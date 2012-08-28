require 'rubygems'
require 'neography'

class Organization
  @neo = Neography::Rest.new :log_enabled => true

  def self.get(name)
    @neo.traverse(@neo.get_root,                          # the node where the traversal starts
      "nodes",                                            # return_type "nodes", "relationships" or "paths"
      {"order" => "breadth first",                        # "breadth first" or "depth first" traversal order
       "uniqueness" => "node global",                     # See Uniqueness in API documentation for options.
       "relationships" => [{"type"=> "organization",      # A hash containg a description of the traversal
                            "direction" => "all"}],       #
       "prune evaluator" => nil,                          # A prune evaluator (when to stop traversing)
       "return filter" => {"name" => name},               # "all" or "all but start node"
       "depth" => 1})
  end
  
  def self.create(name)
    root = @neo.get_root
    org = @neo.create_node("name" => name)
    @neo.create_relationship("organization", root, org)
  end
end