module LinkedData
  module Metrics
    def self.metrics_for_submission(submission,logger)
      submission.bring(:submissionStatus) if submission.bring?(:submissionStatus)

      cls_metrics = class_metrics(submission,logger)

      metrics = LinkedData::Models::Metrics.new
      cls_metrics.each do |k,v|
        metrics.send("#{k}=",v)
      end
      metrics.individuals = number_individuals(submission)
      metrics.properties = number_properties(submission)
      metrics.max_depth = max_depth(submission)
      return metrics
    end

    def self.class_metrics(submission,logger)
      size_page = 2500
      paging = LinkedData::Models::Class.in(submission)
                                        .include(:children,:definition)
                                        .page(1,size_page)
      cls_metrics = {}
      cls_metrics[:classes] = 0
      cls_metrics[:avg_children] = 0
      cls_metrics[:max_children] = 0
      cls_metrics[:classes_one_child] = 0
      cls_metrics[:classes_25_children] = 0
      cls_metrics[:classes_with_no_definition] = 0
      page = 1
      children_counts = []
      begin
        t0 = Time.now
        page_classes = paging.page(page).all
        logger.info("Metrics Classes Page #{page} of #{page_classes.total_pages}"+
                    " classes retrieved in #{Time.now - t0} sec.")
        page_classes.each do |cls|
          cls_metrics[:classes] += 1
          #TODO: investigate
          #for some weird reason NIFSTD brings false:FalseClass here
          unless cls.definition.is_a?(Array) && cls.definition.length > 0
            cls_metrics[:classes_with_no_definition] += 1
          end
          if cls.children.length > 24
            cls_metrics[:classes_25_children] += 1
          end
          if cls.children.length == 1
            cls_metrics[:classes_one_child] += 1
          end
          if cls.children.length > 0
            children_counts << cls.children.length
          end
        end
        page = page_classes.next? ? page + 1 : nil
      end while(!page.nil?)
      if children_counts.length > 0
        cls_metrics[:max_children] = children_counts.max
        sum = 0
        children_counts.each do |x|
          sum += x
        end
        cls_metrics[:avg_children]  = (sum.to_f / children_counts.length).to_i
      end
      return cls_metrics
    end

    def self.number_individuals(submission)
      return count_owl_type(submission.id,"NamedIndividual")
    end

    def self.number_properties(submission)
      props = count_owl_type(submission.id,"DatatypeProperty")
      props += count_owl_type(submission.id,"ObjectProperty")
      return props
    end

    def self.count_owl_type(graph,name)
      owl_type = Goo.namespaces[:owl][name]
      query = <<eof
SELECT (COUNT(?s) as ?count) WHERE {
  GRAPH #{graph.to_ntriples} {
    ?s a #{owl_type.to_ntriples}
  } }
eof
      rs = Goo.sparql_query_client.query(query)
      rs.each do |sol|
        return sol[:count].object
      end
      return 0
    end

    def self.recursive_depth(submission,level)
      return level if level > 50 #just in case
      level = level + 1
      prop = submission.hierarchyProperty
      prop = prop ? prop : Goo.namespaces[:rdfs]["subClassOf"]
      joins = []
      #filter avoids cycles
      vars = Set.new
      level.times do |i|
        joins << "?s#{i} #{prop.to_ntriples} ?s#{i+1} ."
        vars << "?s#{i}"
        vars << "?s#{i+1}"
      end
      joins = joins.join "\n"
      filters = []
      already = Set.new
      vars_cmp = vars.dup
      vars.each do |v1|
        vars.each do |v2|
          next if v1 == v2
          next if already.include?([v1,v2].sort)
          filters << "#{v1} != #{v2}"
          already << [v1,v2].sort
        end
        vars_cmp.delete v1
      end
      filters = filters.join " && "
      query = <<eof
  SELECT * WHERE {
    GRAPH #{submission.id.to_ntriples} {
      #{joins}
      FILTER (#{filters})
    } } 
   LIMIT 1
eof
     rs = Goo.sparql_query_client.query(query)
     rs.each do |sol|
       return recursive_depth(submission,level)
     end
     return level
    end

    def self.max_depth(submission)
      submission.bring(:hierarchyProperty)
      return recursive_depth(submission,0)
    end
  end
end
