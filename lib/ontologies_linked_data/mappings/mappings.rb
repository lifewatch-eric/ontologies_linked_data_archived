module LinkedData
module Mappings

  def self.mapping_predicates()
    predicates = {}
    predicates["CUI"] = ["http://bioportal.bioontology.org/ontologies/umls/cui"]
    predicates["XREF"] = ["http://www.geneontology.org/formats/oboInOwl#xref"]
    predicates["SAME_URI"] = 
      ["http://data.bioontology.org/metadata/def/mappingSameURI"] 
    predicates["LOOM"] = 
      ["http://data.bioontology.org/metadata/def/mappingLoom"] 
    return predicates
  end

  def self.mappings_ontologies(sub1,sub2,page,size,count=false,group=false)
    mappings = []
    union_template = <<-eos
{
  GRAPH <#{sub1.id.to_s}> {
      ?s1 <predicate> ?o .
  }
  GRAPH graph {
      ?s2 <predicate> ?o .
  }
  bind 
}
eos

    blocks = []
    mapping_predicates().each do |_type,mapping_predicate| 
      union_block = union_template.gsub("predicate", mapping_predicate[0])
      if count
        union_block = union_block.sub("bind","")
      else
        union_block = union_block.sub("bind","BIND ('#{_type}' AS ?type)")
      end
      if sub2.nil?
        union_block = union_block.sub("graph","?g")
      else
        union_block = union_block.sub("graph","<#{sub2.id.to_s}>")
      end
      blocks << union_block
    end
    unions = blocks.join("\nUNION\n")

    count_mappings_in_ontology = <<-eos
SELECT variables 
WHERE {
unions
filter
FILTER ((?s1 != ?s2) || (?type = "SAME_URI"))
} page_group 
eos
    query = count_mappings_in_ontology.sub( "unions", unions)
    if count
      if group
        query = query.sub("page_group", "GROUP BY ?g")
        query = query.sub("variables", "?g (count(?s2) as ?c)")
      else
        query = query.sub("page_group","")
        query = query.sub("variables", "(count(?s2) as ?c)")
      end
    else
      variables = "DISTINCT ?s1 ?s2 graph ?type"
      pagination = "OFFSET offset LIMIT limit"
      query = query.sub("page_group",pagination)
      query = query.sub("variables", variables)
    end
    if sub2.nil?
      query = query.sub("graph","?g")
      query = query.sub("filter","FILTER (?g != <#{sub1.id.to_s}>)")
    else
      query = query.sub("graph","")
      query = query.sub("filter","")
    end
    unless count
      limit = size
      offset = (page-1) * size
      query = query.sub("limit", "#{limit}").sub("offset", "#{offset}")
    end
    puts query
    epr = Goo.sparql_query_client(:main)
    graphs = [sub1.id]
    unless sub2.nil?
      graphs << sub2.id
    end
    solutions = epr.query(query,
                          graphs: graphs,
                          query_options: {rules: :NONE})
    group_counts = nil
    if count and group
      group_counts = {}
    end
    solutions.each do |sol|
      if count 
        if group
          binding.pry
          acr = sol[:g].to_s.split("/")[-1]
          group_counts[acr] = sol[:c].object
        else
          return sol["c"].object
        end
      else
        graph2 = nil
        if sub2.nil?
          graph2 = sol[:g]
        else
          graph2 = sub2.id
        end
        terms = [ LinkedData::Models::TermMapping.new(sol[:s1],sub1.id),
                  LinkedData::Models::TermMapping.new(sol[:s2],graph2) ]
        mappings << LinkedData::Models::Mapping.new(terms,sol[:type].to_s)
      end
    end
    unless group_counts.nil?
      return group_counts
    end
    page = Goo::Base::Page.new(page,size,nil,mappings)
    return page
  end

  def self.mappings_ontology(sub,page,size)
    return self.mappings_ontologies(sub,nil,page,size)
  end

  def self.mapping_counts_for_ontology(ont)
    graphs = [LinkedData::Models::TermMapping.type_uri,LinkedData::Models::Mapping.type_uri]
    sparql_query = <<-eos
SELECT DISTINCT ?ont ?id
  WHERE {
  ?id <http://data.bioontology.org/metadata/terms> [
    <http://data.bioontology.org/metadata/ontology> #{ont.id.to_ntriples}  ] .
  ?id <http://data.bioontology.org/metadata/terms> [
    <http://data.bioontology.org/metadata/ontology> ?ont ] .
}
eos
    epr = Goo.sparql_query_client(:main)
    this_acr = ont.id.split("/")[-1]
    results = {}
    solutions = epr.query(sparql_query, 
                          graphs: graphs,
                          query_options: {rules: :NONE},
                          content_type: "text/plain")
    line = 0
    solutions.split("\n").each do |sol|
      if line > 0
        ont,id = sol.split("\t")
        acr = ont[1..-2].to_s.split("/")[-1]
        if acr != this_acr
          if !results.include?(acr)
            results[acr] = Set.new
          end
          results[acr] << id
        end
      end
      line += 1
    end
    counts = {}
    results.each do |k,v|
      counts[k]=v.length
    end
    return counts
  end

  def self.mapping_counts_per_ontology()
    graphs = [LinkedData::Models::TermMapping.type_uri,LinkedData::Models::Mapping.type_uri]
    sparql_query = <<-eos
SELECT ?ont (count(*) as ?count)
  WHERE {
  ?id <http://data.bioontology.org/metadata/terms> [
    <http://data.bioontology.org/metadata/ontology> ?ont ] .
} GROUP BY ?ont
eos
    epr = Goo.sparql_query_client(:main)
    results = {}
    solutions = epr.query(sparql_query, graphs: graphs,query_options: {rules: :NONE})
    solutions.each do |sol|
      acr = sol[:ont].to_s.split("/")[-1]
      results[acr] = sol[:count].object
    end
    return results
  end

  def self.recent_user_mappings(n)
    graphs = [LinkedData::Models::MappingProcess.type_uri]
    qdate = <<-eos
SELECT ?s
FROM <#{LinkedData::Models::MappingProcess.type_uri}>
WHERE { ?s <http://data.bioontology.org/metadata/date> ?o } ORDER BY DESC(?o) LIMIT #{n}
eos
    epr = Goo.sparql_query_client(:main)
    procs = []
    epr.query(qdate, graphs: graphs,query_options: {rules: :NONE}).each do |sol|
      procs << sol[:s]
    end
    if procs.length == 0 
      return []
    end
    graphs = [LinkedData::Models::MappingProcess.type_uri]
    procs = procs.map { |x| "?o = #{x.to_ntriples}" }.join " || "
    qmappings = <<-eos
SELECT ?s
FROM <#{LinkedData::Models::Mapping.type_uri}>
WHERE { ?s <http://data.bioontology.org/metadata/process> ?o .
FILTER (#{procs})
}
eos
    epr = Goo.sparql_query_client(:main)
    mapping_ids = []
    epr.query(qmappings, graphs: graphs,query_options: {rules: :NONE}).each do |sol|
      mapping_ids << sol[:s]
    end
    mappings = mapping_ids.map { |x| LinkedData::Models::Mapping.find(x)
                                     .include(terms: [ :term, ontology: [ :acronym ] ])
                                     .include(process: [:name, :creator, :date ])
                                     .first 
                               }
    return mappings.sort_by { |x| x.process.first.date }.reverse[0..n-1]
  end

end
end
