require_relative '../utils'

class Projectile
  MOVEMENT_RATE = 3.5
  MAXIMUM_RANGE = 180
  COLLISION_RADIUS = 4

  attr_reader :position, :direction, :velocity, :renderer
  attr_reader :dead, :start_position, :circle, :damage_type

  def initialize(position, direction, color, renderer, damage_type: :projectile_collision)
    @position = position
    @start_position = position
    @direction = direction
    @renderer = renderer
    @damage_type = damage_type
    @velocity = MOVEMENT_RATE
    @dead = false

    return if HEADLESS
    @circle = @renderer.circle(
      x: @position[0] - 1.5,
      y: @position[1] - 1.5,
      radius: 3,
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

    @circle.x = @position[0]
    @circle.y = @position[1]
  end
end
