require_relative './entity'
require_relative './capabilities/ownable'
require_relative './capabilities/buildable'
require_relative './capabilities/collidable'
require_relative './capabilities/manoeuvrable'

class Vehicle < Entity
  include Ownable
  include Buildable
  include Collidable
  include Manoeuvrable

  def initialize(renderer, position, player, max_health:, health: nil, built: false, cost: max_health * 10, direction: rand * Math::PI * 2, physics: DEFAULT_PHYSICS, turn_rate: 1.0, movement_rate: 1.0, collision_radius:)
    super(renderer, position)
    initialize_ownable(player: player)
    initialize_buildable(max_health: max_health, health: health, built: built, cost: cost)
    initialize_collidable(collision_radius: collision_radius)
    initialize_manoeuvrable(physics: physics, velocity: 0.0, direction: direction, angular_velocity: 0.0)
    @movement_rate = movement_rate
    @turn_rate = turn_rate
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
