require_relative './entity'
require_relative './ownable'
require_relative './killable'
require_relative './buildable'
require_relative './collidable'

class Structure < Entity
  include Ownable
  include Killable
  include Buildable
  include Collidable

  def initialize(renderer, position, player, max_health:, health: max_health, built: false, collision_radius:)
    super(renderer, position)
    @player = player
    @max_health = max_health
    @health = health
    @built = built
    @dead = false
    @collision_radius = collision_radius
  end
end
