require 'matrix'
require_relative './vehicle_physics'
require_relative './utils'

class Vehicle
  attr_reader :physics, :scale_factor, :velocity_scale_factor
  attr_reader :position, :direction, :velocity, :angular_velocity
  attr_reader :dead, :circle, :line

  def initialize(position: Vector[0, 0], direction: 0.0, physics: DEFAULT_VEHICLE_PHYSICS, scale_factor: 1.0, velocity_scale_factor: 1.0)
    @position = position
    @direction = direction
    @physics = physics
    @scale_factor = scale_factor
    @velocity_scale_factor = velocity_scale_factor
    @velocity = 0.0
    @angular_velocity = 0.0
    @dead = false

    @circle = Circle.new(
      x: (@position[0] - 2.5) * @scale_factor,
      y: (@position[1] - 2.5) * @scale_factor,
      radius: @scale_factor * 5,
      color: 'white',
      segments: 20,
      z: 2,
    )
    v = vector_from_magnitude_and_direction(@scale_factor * 5.0, @direction)
    @line = Line.new(
      x1: @position[0] * @scale_factor,
      y1: @position[1] * @scale_factor,
      x2: @position[0] * @scale_factor + v[0],
      y2: @position[1] * @scale_factor + v[1],
      width: 3 * @scale_factor, # FIXME: Base this on @scale_factor
      color: 'black',
      z: 2,
    )
  end

  def kill
    @dead = true
    @circle.remove
    @line.remove
  end

  def color
    @circle.color
  end

  def color=(color)
    @circle.color = color
  end

  def update(accelerate_mode: "forward")
    return if @dead

    apply_drag_forces

    case accelerate_mode
    when "forward"
      accelerate
    when "forward_and_left"
      accelerate(offset: @physics.turning_angle)
    when "forward_and_right"
      accelerate(offset: -@physics.turning_angle)
    when ""
    else
      raise "unexpected accelerate mode: #{accelerate_mode}"
    end

    @direction += @angular_velocity * @scale_factor
    @direction += Math::PI * 2 if @direction < -Math::PI
    @direction -= Math::PI * 2 if @direction > Math::PI
    movement_vector = vector_from_magnitude_and_direction(@velocity * @scale_factor * @velocity_scale_factor, @direction)
    @position += movement_vector
  end

  def render
    return if @dead

    @circle.x = @position[0] * @scale_factor
    @circle.y = @position[1] * @scale_factor

    v = vector_from_magnitude_and_direction(@scale_factor * 5.0, @direction)
    @line.x1 = @position[0] * @scale_factor
    @line.y1 = @position[1] * @scale_factor
    @line.x2 = @position[0] * @scale_factor + v[0]
    @line.y2 = @position[1] * @scale_factor + v[1]
  end

  def collided?(other_vehicle)
    distance = (@position - other_vehicle.position).magnitude
    distance <= 10.0
  end

  def going_south?
    @direction.abs < Math::PI / 2
  end

  def going_east?
    @direction > 0
  end

  def turn_left_to_reach?(destination)
    offset = destination - @position
    distance, angle = magnitude_and_direction_from_vector(offset)
    (@direction - angle) % (Math::PI * 2) > Math::PI
  end

  def turn_right_to_reach?(destination)
    offset = destination - @position
    distance, angle = magnitude_and_direction_from_vector(offset)
    (@direction - angle) % (Math::PI * 2) < Math::PI
  end

protected

  def apply_drag_forces
    apply_drag_to_velocity @physics.air_resistance(@velocity)
    apply_drag_to_angular_velocity @physics.air_resistance(@angular_velocity)

    rolling_resistance_per_unit_velocity = @physics.rolling_resistance / (@velocity + @angular_velocity)
    rolling_resistance_per_unit_velocity = 0 if rolling_resistance_per_unit_velocity.infinite?
    apply_drag_to_velocity rolling_resistance_per_unit_velocity * @velocity
    apply_drag_to_angular_velocity rolling_resistance_per_unit_velocity * @angular_velocity

    # FIXME: Drag should probably be applied after acceleration, but maaaybe based upon the previous
    # velocity. Otherwise drag will be clipped to zero before the acceleration, making it artificially
    # quick at first.
  end

  def apply_drag_to_velocity(max_drag_force)
    drag_force = [max_drag_force.abs, @physics.momentum(@velocity.abs)].min
    apply_forwards_force(-drag_force * sign_of(@velocity))
  end

  def apply_drag_to_angular_velocity(max_drag_force)
    drag_force = [max_drag_force.abs, @physics.momentum(@angular_velocity.abs)].min
    apply_angular_force(-drag_force * sign_of(@angular_velocity))
  end

  def apply_forwards_force(force)
    velocity_change = force / @physics.mass
    @velocity += velocity_change
  end

  def apply_angular_force(force)
    velocity_change = force / @physics.mass
    @angular_velocity += velocity_change
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

  def accelerate(offset: 0.0)
    acceleration_force_vector = vector_from_magnitude_and_direction(@physics.max_acceleration_force, offset)
    apply_angular_force(acceleration_force_vector[0])
    apply_forwards_force(acceleration_force_vector[1])
  end
end
