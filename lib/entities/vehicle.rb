require 'matrix'
require_relative '../utils'
require_relative './entity'
require_relative './ownable'
require_relative './killable'
require_relative './buildable'
require_relative './collidable'
require_relative './movable'
require_relative './manoeuvrable'

class Vehicle < Entity
  include Ownable
  include Killable
  include Buildable
  include Collidable
  include Movable
  include Manoeuvrable

  def initialize(renderer, position, player, max_health:, health: max_health, built: true, direction: rand * Math::PI * 2, physics: DEFAULT_PHYSICS, turn_rate: 1.0, movement_rate: 1.0, collision_radius:)
    super(renderer, position)
    @player = player
    @max_health = max_health
    @health = health
    @dead = false
    @built = built
    @velocity = 0.0
    @direction = direction
    @angular_velocity = 0.0
    @physics = physics
    @movement_rate = movement_rate
    @turn_rate = turn_rate
    @collision_radius = collision_radius
  end

  def update(move)
    return if @dead

    case move
    when :stop
      apply_drag_forces
    when :forward
      update_velocities(turning_angle: 0.0)
    when :turn_left
      update_velocities(turning_angle: @physics.turning_angle)
    when :turn_right
      update_velocities(turning_angle: -@physics.turning_angle)
    else
      raise "unexpected move: #{move}"
    end

    update_direction(multiplier: @turn_rate)
    update_position(multiplier: @movement_rate)
  end
end
