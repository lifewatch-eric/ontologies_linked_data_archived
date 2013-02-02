require_relative "../../config/default.rb"
require_relative "../../lib/ontologies_linked_data"
require "pry"
Goo.stores.each do |store|
  name = store[:name]

  next if store[:host] != "localhost"

  print "Deleting all data in '#{name}' store '#{store[:host]}:#{store[:port]}'. Type 'y' to confirm: "
  $stdout.flush
  confirm = $stdin.gets
  if !(confirm.strip == 'y')
    puts " ---> cancel received"
    next
  end
  print "deleting ..."
  $stdout.flush
  Goo.store.update("DELETE {?s ?p ?o } WHERE { ?s ?p ?o }")
  no_triples = nil
  rs = Goo.store.query("SELECT (COUNT(?s) as ?c) WHERE { ?s ?p ?o }")
  rs.each_solution do |s|
    no_triples = s.get(:c).value
  end
  puts " OK -> #triples #{no_triples}"
end
