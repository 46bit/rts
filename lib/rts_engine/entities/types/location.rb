require_relative "./entity"
require_relative "../capabilities/ownable"
require_relative "../capabilities/collidable"

class Location < Entity
  include Collidable

  attr_accessor :structure

  def initialize(renderer, position, collision_radius:, structure: nil)
    super(renderer, position)
    initialize_collidable(collision_radius: collision_radius)
    @structure = structure
  end
end
