require_relative './entity'
require_relative './ownable'
require_relative './collidable'

class Location < Entity
  include Ownable
  include Collidable

  def initialize(renderer, position, player: nil, collision_radius:)
    super(renderer, position)
    @player = player
    @collision_radius = collision_radius
  end
end
