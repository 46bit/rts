require_relative "./entity"
require_relative "../capabilities/movable"
require_relative "../capabilities/killable"
require_relative "../capabilities/collidable"

class Projectile < Entity
  include Ownable
  include Movable
  include Killable
  include Collidable

  attr_reader :start_position, :range, :damage

  def initialize(renderer, position, velocity, direction, range, damage, player, collision_radius:)
    super(renderer, position)
    initialize_ownable(player: player)
    initialize_movable(velocity: velocity, direction: direction)
    initialize_killable(max_health: 1, health: 1)
    initialize_collidable(collision_radius: collision_radius)
    @start_position = position
    @range = range
    @damage = damage
  end

  def update
    return if dead?

    update_position
    kill if (@position - @start_position).magnitude > @range
  end
end
