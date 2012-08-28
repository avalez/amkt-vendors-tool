require 'rubygems'
require 'neography'

@neo = Neography::Rest.new :log_enabled => true

 def get_org(name)
    @neo.execute_query("start root=node(0) match root-[:organization]-org where org.name = orgName return org",
      {:orgName=> name})   
 end
  
 def create_org(name)
    root = @neo.get_root
    org = @neo.create_node("name" => name)
    @neo.create_relationship("organization", root, org)
 end

#puts create_org "Acme"
puts get_org "Acme"

#ERROR -- : Invalid data sent {"message":"expected node id, or *\n\"start root=node(id) match root-[:organization]-org where org.name = 'Acme' return org\"\n                 ^",
# OR
#ERROR -- : Invalid data sent {"message":"Unknown identifier `orgName`",