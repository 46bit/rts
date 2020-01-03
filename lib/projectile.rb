require 'matrix'
require_relative './vehicle_physics'
require_relative './utils'

class Projectile
  # FIXME: Have a maximum range as well
  MOVEMENT_RATE = 3.5
  MAXIMUM_RANGE = 180

  attr_reader :position, :direction, :velocity
  attr_reader :dead, :start_position, :circle

  def initialize(position, direction, color, scale_factor: 1.0)
    @position = position
    @start_position = position
    @direction = direction
    @scale_factor = scale_factor
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
    # @range_circle = Circle.new(
    #   x: (@position[0] - 1.5) * @scale_factor,
    #   y: (@position[1] - 1.5) * @scale_factor,
    #   radius: scale_factor * MAXIMUM_RANGE,
    #   color: color,
    #   opacity: 0.1,
    #   z: 0,
    # )
  end

  def kill
    @dead = true
    return if HEADLESS
    @circle.remove
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
