require_relative '../utils'

class Projectile
  MOVEMENT_RATE = 3.5
  MAXIMUM_RANGE = 180
  COLLISION_RADIUS = 4

  attr_reader :position, :direction, :velocity, :scale_factor
  attr_reader :dead, :start_position, :circle, :damage_type

  def initialize(position, direction, color, scale_factor: 1.0, damage_type: :projectile_collision)
    @position = position
    @start_position = position
    @direction = direction
    @scale_factor = scale_factor
    @damage_type = damage_type
    @velocity = MOVEMENT_RATE * @scale_factor
    @dead = false

    return if HEADLESS
    @circle = Circle.new(
      x: (@position[0] - 1.5) * @scale_factor,
      y: (@position[1] - 1.5) * @scale_factor,
      radius: scale_factor * 3,
      color: color,
      opacity: 0.7,
      z: 5,
    )
  end

  def kill
    @dead = true
    @circle.remove unless HEADLESS
  end

  def update
    return if @dead

    movement_vector = vector_from_magnitude_and_direction(@velocity, @direction)
    @position += movement_vector

    kill if (@position - @start_position).magnitude > MAXIMUM_RANGE
  end

  def render
    return if @dead

    @circle.x = @position[0] * @scale_factor
    @circle.y = @position[1] * @scale_factor
  end
end
