require 'matrix'
require_relative './vehicle_physics'
require_relative './utils'

class Vehicle
  PHYSICS = DEFAULT_VEHICLE_PHYSICS
  MOVEMENT_RATE = 0.1
  TURN_RATE = 4.0/3.0

  attr_reader :scale_factor
  attr_reader :position, :player, :direction, :velocity, :angular_velocity
  attr_reader :dead, :circle, :line

  def initialize(position, player, direction: rand * Math::PI * 2, scale_factor: 1.0)
    @position = position
    @player = player
    @direction = direction
    @scale_factor = scale_factor
    @velocity = 0.0
    @angular_velocity = 0.0
    @dead = false

    return if HEADLESS
    @circle = Circle.new(
      x: (@position[0] - 2.5) * @scale_factor,
      y: (@position[1] - 2.5) * @scale_factor,
      radius: @scale_factor * 5,
      color: @player.color,
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
    return if HEADLESS
    @circle.remove
    @line.remove
  end

  def update(accelerate_mode: "forward")
    return if @dead

    apply_drag_forces

    case accelerate_mode
    when "forward"
      accelerate
    when "forward_and_left"
      accelerate(offset: PHYSICS.turning_angle)
    when "forward_and_right"
      accelerate(offset: -PHYSICS.turning_angle)
    when ""
    else
      raise "unexpected accelerate mode: #{accelerate_mode}"
    end

    @direction += @angular_velocity * TURN_RATE
    @direction += Math::PI * 2 if @direction < -Math::PI
    @direction -= Math::PI * 2 if @direction > Math::PI
    movement_vector = vector_from_magnitude_and_direction(@velocity * MOVEMENT_RATE, @direction)
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

  def collided_with_vehicle?(other_vehicle)
    distance = (@position - other_vehicle.position).magnitude
    distance <= 10.0
  end

  def collided_with_projectile?(projectile)
    distance = (@position - projectile.position).magnitude
    # FIXME: How about increasing this to give projectiles a bigger area of effect?
    # Projectiles are weak against factories, and it'd make sense if that's because
    # they have a big but weaker explosion?
    distance <= 8
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
    apply_drag_to_velocity PHYSICS.air_resistance(@velocity)
    apply_drag_to_angular_velocity PHYSICS.air_resistance(@angular_velocity)

    rolling_resistance_per_unit_velocity = PHYSICS.rolling_resistance / (@velocity + @angular_velocity)
    rolling_resistance_per_unit_velocity = 0 if rolling_resistance_per_unit_velocity.infinite?
    apply_drag_to_velocity rolling_resistance_per_unit_velocity * @velocity
    apply_drag_to_angular_velocity rolling_resistance_per_unit_velocity * @angular_velocity

    # FIXME: Drag should probably be applied after acceleration, but maaaybe based upon the previous
    # velocity. Otherwise drag will be clipped to zero before the acceleration, making it artificially
    # quick at first.
  end

  def apply_drag_to_velocity(max_drag_force)
    drag_force = [max_drag_force.abs, PHYSICS.momentum(@velocity.abs)].min
    apply_forwards_force(-drag_force * sign_of(@velocity))
  end

  def apply_drag_to_angular_velocity(max_drag_force)
    drag_force = [max_drag_force.abs, PHYSICS.momentum(@angular_velocity.abs)].min
    apply_angular_force(-drag_force * sign_of(@angular_velocity))
  end

  def apply_forwards_force(force)
    velocity_change = force / PHYSICS.mass
    @velocity += velocity_change
  end

  def apply_angular_force(force)
    velocity_change = force / PHYSICS.mass
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
    acceleration_force_vector = vector_from_magnitude_and_direction(PHYSICS.max_acceleration_force, offset)
    apply_angular_force(acceleration_force_vector[0])
    apply_forwards_force(acceleration_force_vector[1])
  end
end
