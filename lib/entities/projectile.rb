require_relative '../utils'

class Projectile
  MOVEMENT_RATE = 3.5
  MAXIMUM_RANGE = 180
  COLLISION_RADIUS = 4

  attr_reader :position, :direction, :velocity, :renderer, :damage_type
  attr_reader :dead, :start_position, :circle, :triangle

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
    vector_to_point_on_circle = vector_from_magnitude_and_direction(3, @direction + Math::PI / 2)
    vector_to_tail_point = vector_from_magnitude_and_direction(6, @direction)
    @triangle = @renderer.triangle(
      x1: @position[0] + vector_to_point_on_circle[0],
      y1: @position[1] + vector_to_point_on_circle[1] ,
      x2: @position[0] - vector_to_point_on_circle[0],
      y2: @position[1] - vector_to_point_on_circle[1],
      x3: @position[0] - vector_to_tail_point[0],
      y3: @position[1] - vector_to_tail_point[1],
      color: color,
      opacity: 0.7,
      z: 5,
    )
  end

  def kill
    @dead = true
    return if HEADLESS
    @circle.remove
    @triangle.remove
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

    vector_to_point_on_circle = vector_from_magnitude_and_direction(3, @direction + Math::PI / 2)
    vector_to_tail_point = vector_from_magnitude_and_direction(6, @direction)
    @triangle.x1 = @position[0] + vector_to_point_on_circle[0]
    @triangle.y1 = @position[1] + vector_to_point_on_circle[1]
    @triangle.x2 = @position[0] - vector_to_point_on_circle[0]
    @triangle.y2 = @position[1] - vector_to_point_on_circle[1]
    @triangle.x3 = @position[0] - vector_to_tail_point[0]
    @triangle.y3 = @position[1] - vector_to_tail_point[1]
  end
end
