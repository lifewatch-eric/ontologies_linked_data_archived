module LinkedData
module Mappings

  def self.mapping_predicates()
    predicates = {}
    predicates["CUI"] = ["http://bioportal.bioontology.org/ontologies/umls/cui"]
    predicates["XREF"] = ["http://www.geneontology.org/formats/oboInOwl#hasDbXref"]
    predicates["SAME_URI"] = 
      ["http://data.bioontology.org/metadata/def/mappingSameURI"] 
    predicates["LOOM"] = 
      ["http://data.bioontology.org/metadata/def/mappingLoom"] 
    predicates["REST"] =
      ["http://data.bioontology.org/metadata/def/mappingRest"]
    return predicates
  end

  def self.mapping_ontologies_count(sub1,sub2)
    template = <<-eos
{
  GRAPH <#{sub1.id.to_s}> {
      ?s1 <predicate> ?o .
  }
  GRAPH graph {
      ?s2 <predicate> ?o .
  }
}
eos
    group_count = nil
    count = 0
    if sub2.nil?
      group_count = {}
    end
    mapping_predicates().each do |_type,mapping_predicate| 
      block = template.gsub("predicate", mapping_predicate[0])
      if sub2.nil?
      else
      end
      query_template = <<-eos
      SELECT variables 
      WHERE {
      block
      filter
      } group
      eos
      query = query_template.sub("block", block)
      filter = ""
      if _type != "SAME_URI"
        filter += "FILTER (?s1 != ?s2)"
      end
      if sub2.nil?
        filter += "\nFILTER (?g != <#{sub1.id.to_s}>)"
        query = query.sub("graph","?g")
        query = query.sub("filter",filter)
        query = query.sub("variables","?g (count(?s1) as ?c)")
        query = query.sub("group", "GROUP BY ?g")
      else
        query = query.sub("graph","<#{sub2.id.to_s}>")
        query = query.sub("filter",filter)
        query = query.sub("group","")
        query = query.sub("variables","(count(?s1) as ?c)")
      end
      epr = Goo.sparql_query_client(:main)
      graphs = [sub1.id]
      unless sub2.nil?
        graphs << sub2.id
      end
      solutions = epr.query(query,
                            graphs: graphs,
                            query_options: {rules: :NONE})
      solutions.each do |sol|
        if sub2.nil?
          acr = sol[:g].to_s.split("/")[-3]
          unless group_count.include?(acr)
            group_count[acr] = 0
          end
          group_count[acr] += sol[:c].object
        else
          count += sol[:c].object
        end
      end
    end #per predicate query

    if sub2.nil?
      return group_count
    end
    return count
  end

  def self.mappings_ontologies(sub1,sub2,page,size,classId=nil)
    mappings = []
    union_template = <<-eos
{
  GRAPH <#{sub1.id.to_s}> {
      classId <predicate> ?o .
  }
  GRAPH graph {
      ?s2 <predicate> ?o .
  }
  bind 
}
eos

    if classId.nil?
      union_template = union_template.sub("classId", "?s1")
    else
      union_template = union_template.sub("classId", "<#{classId.to_s}>")
    end

    blocks = []
    mapping_predicates().each do |_type,mapping_predicate| 
      union_block = union_template.gsub("predicate", mapping_predicate[0])
      union_block = union_block.sub("bind","BIND ('#{_type}' AS ?type)")
      if sub2.nil?
        union_block = union_block.sub("graph","?g")
      else
        union_block = union_block.sub("graph","<#{sub2.id.to_s}>")
      end
      blocks << union_block
    end
    unions = blocks.join("\nUNION\n")

    mappings_in_ontology = <<-eos
SELECT variables 
WHERE {
unions
filter
} page_group 
eos
    query = mappings_in_ontology.sub( "unions", unions)
    variables = "?s2 graph ?type"
    if classId.nil?
      variables = "?s1 " + variables
    end
    query = query.sub("variables", variables)
    filter = ""
    if classId.nil?
      filter = "FILTER ((?s1 != ?s2) || (?type = 'SAME_URI'))"
    else
      filter = ""
    end
    if sub2.nil?
      query = query.sub("graph","?g")
      filter += "\nFILTER (?g != <#{sub1.id.to_s}>)"
      query = query.sub("filter",filter)
    else
      query = query.sub("graph","")
      query = query.sub("filter",filter)
    end
    if size > 0
      pagination = "OFFSET offset LIMIT limit"
      query = query.sub("page_group",pagination)
      limit = size
      offset = (page-1) * size
      query = query.sub("limit", "#{limit}").sub("offset", "#{offset}")
    else
      query = query.sub("page_group","")
    end
    epr = Goo.sparql_query_client(:main)
    graphs = [sub1.id]
    unless sub2.nil?
      graphs << sub2.id
    end
    solutions = epr.query(query,
                          graphs: graphs,
                          query_options: {rules: :NONE})
    s1 = nil
    unless classId.nil?
      s1 = RDF::URI.new(classId.to_s)
    end
    solutions.each do |sol|
      graph2 = nil
      if sub2.nil?
        graph2 = sol[:g]
      else
        graph2 = sub2.id
      end
      if classId.nil?
        s1 = sol[:s1]
      end
      classes = [ read_only_class(s1.to_s,sub1.id.to_s),
                read_only_class(sol[:s2].to_s,graph2.to_s) ]
      mappings << LinkedData::Models::Mapping.new(classes,sol[:type].to_s)
    end
    if size == 0
      return mappings
    end
    page = Goo::Base::Page.new(page,size,nil,mappings)
    counts = mapping_ontologies_count(sub1,sub2)
    if counts.instance_of?(Hash)
      total = 0
      counts.each do |k,v|
        total = total + v
      end
      page.aggregate = total
    else
      page.aggregate = counts
    end
    return page
  end

  def self.mappings_ontology(sub,page,size,classId=nil)
    return self.mappings_ontologies(sub,nil,page,size,classId=classId)
  end

  def self.read_only_class(classId,submissionId)
      ontologyId = submissionId.split("/")[0..-3]
      acronym = ontologyId.last
      ontologyId = ontologyId.join("/")
      ontology = LinkedData::Models::Ontology
            .read_only(
              id: RDF::IRI.new(ontologyId),
              acronym: acronym)
      submission = LinkedData::Models::OntologySubmission
            .read_only(
              id: RDF::IRI.new(ontologyId+"/submissions/latest"),
              ontology: ontology)
      mappedClass = LinkedData::Models::Class
            .read_only(
              id: RDF::IRI.new(classId), 
              submission: submission,
              urn_id: LinkedData::Models::Class.urn_id(acronym,classId) )
      return mappedClass
  end

  def self.migrate_rest_mappings(acronym)
    mappings = LinkedData::Models::RestBackupMapping
                .where.include(:uuid, :class_urns, :process).all
    if mappings.length == 0
      return []
    end
    triples = []

    rest_predicate = mapping_predicates()["REST"][0]
    mappings.each do |m|
      m.class_urns.each do |u|
        u = u.to_s
        if u.start_with?("urn:#{acronym}")
          class_id = u.split(":")[2..-1].join(":")
          triples << 
            " <#{class_id}> <#{rest_predicate}> <#{m.id}> . "
        end
      end
    end
    return triples
    
  end

  def self.create_rest_mapping(classes,process)
    unless process.instance_of? LinkedData::Models::MappingProcess
      raise ArgumentError, "Process should be instance of MappingProcess"
    end
    if classes.length != 2
      raise ArgumentError, "Create REST is avalaible for two classes. " +
                           "Request contains #{classes.length} classes."
    end
    #first create back up mapping that lives across submissions
    backup_mapping = LinkedData::Models::RestBackupMapping.new
    backup_mapping.uuid = UUID.new.generate
    backup_mapping.process = process
    class_urns = []
    classes.each do |c|
      if c.instance_of?LinkedData::Models::Class
        acronym = c.submission.id.to_s.split("/")[-3]
        class_urns << RDF::URI.new(
          LinkedData::Models::Class.urn_id(acronym,c.id.to_s))
          
      else
        class_urns << RDF::URI.new(c.urn_id())
      end
    end
    backup_mapping.class_urns = class_urns
    backup_mapping.save

    #second add the mapping id to current submission graphs
    rest_predicate = mapping_predicates()["REST"][0]
    classes.each do |c|
      sub = c.submission
      unless sub.id.to_s["latest"].nil?
        #the submission in the class might point to latest
        sub = LinkedData::Models::Ontology.find(c.submission.ontology.id)
                .first
                .latest_submission
      end
      query_update =<<eof
INSERT DATA {
GRAPH <#{sub.id.to_s}> {
  <#{c.id.to_s}> <#{rest_predicate}> <#{backup_mapping.id.to_s}> .
  }
}
eof
        Goo.sparql_update_client.update(query_update, graph: sub.id) 
    end
    mapping = LinkedData::Models::Mapping.new(classes,"REST",process)
    return mapping
  end

end
end
