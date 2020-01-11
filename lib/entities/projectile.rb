require_relative './entity'
require_relative './capabilities/movable'
require_relative './capabilities/killable'
require_relative './capabilities/collidable'

class Projectile < Entity
  include Ownable
  include Movable
  include Killable
  include Collidable

  attr_reader :start_position, :range, :damage, :teardrop

  def initialize(renderer, position, velocity, direction, range, damage, width, length, player, opacity: 1.0, z: 999, collision_radius:)
    super(renderer, position)
    initialize_ownable(player: player)
    initialize_movable(velocity: velocity, direction: direction)
    initialize_killable(max_health: 1, health: 1)
    initialize_collidable(collision_radius: collision_radius)
    @start_position = position
    @range = range
    @damage = damage

    prerender(width, length, opacity, z) unless HEADLESS
  end

  def prerender(width, length, opacity, z)
    @teardrop = @renderer.teardrop(
      x: @position[0],
      y: @position[1],
      direction: @direction,
      width: width,
      length: length,
      color: @player.color,
      opacity: opacity,
      z: z,
    )
  end

  def kill
    super
    @teardrop.remove unless HEADLESS
  end

  def update
    return if dead?
    update_position
    kill if (@position - @start_position).magnitude > @range
  end

  def render
    return if @dead
    @teardrop.x = @position[0]
    @teardrop.y = @position[1]
  end
end
