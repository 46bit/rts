require_relative "../physics"
require_relative "./movable"

module Manoeuvrable
  include Movable

  attr_reader :physics, :angular_velocity

  def initialize_manoeuvrable(physics: DEFAULT_PHYSICS, velocity: 0.0, direction: 0.0, angular_velocity: 0.0)
    initialize_movable(velocity: velocity, direction: direction)
    @physics = physics
    @angular_velocity = angular_velocity
  end

  def update_velocities(turning_angle: 0.0, force_multiplier: 1.0)
    # FIXME: Drag should be applied after acceleration, but based on the previous velocity?
    apply_drag_forces

    acceleration_forces = vector_from_magnitude_and_direction(
      @physics.max_acceleration_force,
      turning_angle,
    )
    @angular_velocity += acceleration_forces[0] / @physics.mass
    @velocity += acceleration_forces[1] * force_multiplier.to_f / @physics.mass
  end

  def update_direction(multiplier: 1.0)
    @direction += @angular_velocity * multiplier
    # Normalise @direction to keep within [-PI, PI]
    @direction += Math::PI * 2 if @direction < -Math::PI
    @direction -= Math::PI * 2 if @direction > Math::PI
  end

  def turn_left_to_reach?(destination)
    offset = destination - @position
    _, angle = magnitude_and_direction_from_vector(offset)
    (@direction - angle) % (Math::PI * 2) > Math::PI
  end

  def turn_right_to_reach?(destination)
    offset = destination - @position
    _, angle = magnitude_and_direction_from_vector(offset)
    (@direction - angle) % (Math::PI * 2) < Math::PI
  end

protected

  def drag_force(force, velocity)
    drag_force = [force.abs, @physics.momentum(velocity.abs)].min
    drag_force * sign_of(velocity)
  end

  def apply_drag_forces
    @velocity -= drag_force(@physics.air_resistance(@velocity), @velocity)
    @angular_velocity -= drag_force(@physics.air_resistance(@angular_velocity), @angular_velocity)

    rolling_resistance_forces = @physics.rolling_resistance_forces(@velocity, @angular_velocity)
    @velocity -= drag_force(rolling_resistance_forces[0], @velocity)
    @angular_velocity -= drag_force(rolling_resistance_forces[1], @angular_velocity)
  end

  def sign_of(f)
    if f.infinite?
      raise "infinite value to sign_of"
    elsif f.zero?
      1
    else
      f / f.abs
    end
  end
end
