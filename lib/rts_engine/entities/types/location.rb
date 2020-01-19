require_relative "./entity"
require_relative "../capabilities/collidable"

class Location < Entity
  include Collidable

  attr_accessor :structure

  def initialize(position, collision_radius:, structure: nil)
    super(position)
    initialize_collidable(collision_radius: collision_radius)
    @structure = structure
  end
end
