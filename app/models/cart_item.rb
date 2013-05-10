class CartItem < ActiveRecord::Base
  belongs_to :cart
  belongs_to :ontology_version
  
  attr_accessible :ontology_version, :ontology_version_id, :cart
end