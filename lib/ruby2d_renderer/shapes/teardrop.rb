require_relative "../../utils"

# FIXME: Make more parameters editable
class RenderTeardrop
  attr_reader :x, :y, :circle, :triangle

  def initialize(renderer, x:, y:, direction:, width:, length: 2 * radius, color:, opacity: nil, z: nil)
    @x = x
    @y = y
    radius = width / 2.0
    @circle = renderer.circle(
      x: x,
      y: y,
      radius: radius,
      color: color,
      opacity: opacity,
      z: z,
    )
    vector_to_point_on_circle = vector_from_magnitude_and_direction(radius, direction + Math::PI / 2)
    vector_to_tail_point = vector_from_magnitude_and_direction(length, direction)
    @triangle = renderer.triangle(
      x1: x + vector_to_point_on_circle[0],
      y1: y + vector_to_point_on_circle[1],
      x2: x - vector_to_point_on_circle[0],
      y2: y - vector_to_point_on_circle[1],
      x3: x - vector_to_tail_point[0],
      y3: y - vector_to_tail_point[1],
      color: color,
      opacity: opacity,
      z: z,
    )
  end

  def x=(x)
    @circle.x += x - @x
    @triangle.x1 += x - @x
    @triangle.x2 += x - @x
    @triangle.x3 += x - @x
    @x = x
  end

  def y=(y)
    @circle.y += y - @y
    @triangle.y1 += y - @y
    @triangle.y2 += y - @y
    @triangle.y3 += y - @y
    @y = y
  end

  def recompute
    @circle.recompute
    @triangle.recompute
  end

  def remove
    @circle.remove
    @triangle.remove
  end

  def add
    @circle.add
    @triangle.add
  end
end
