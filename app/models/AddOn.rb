require 'rubygems'
require 'neography'

class AddOn
  @neo = Neography::Rest.new
  
  def self.create(name)
    root = @neo.get_root
    org = @neo.create_node("name" => name)
    @neo.create_relationship("addOn", root, org)
  end
end