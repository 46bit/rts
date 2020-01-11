require_relative './entity'
require_relative './capabilities/ownable'
require_relative './capabilities/collidable'

class Location < Entity
  include Ownable
  include Collidable

  def initialize(renderer, position, player: nil, collision_radius:)
    super(renderer, position)
    initialize_ownable(player: player)
    initialize_collidable(collision_radius: collision_radius)
  end

  def player=(player)
    @player = player
  end
end
