require_relative "./types/unit"

class TankPresenter < UnitPresenter
  RADIUS = 8.0

  attr_reader :circle, :square, :line

  def prerender
    super
    @circle ||= @renderer.circle(
      x: @entity.x,
      y: @entity.y,
      radius: RADIUS,
      color: @entity.player.color,
      segments: 20,
      z: 2,
    )
    vector_to_point_on_circle = vector_from_magnitude_and_direction(RADIUS, @entity.direction + Math::PI / 2)
    vector_to_front_of_unit = vector_from_magnitude_and_direction(RADIUS + 2, @entity.direction)
    @square ||= @renderer.quad(
      x1: @entity.x + vector_to_point_on_circle[0],
      y1: @entity.y + vector_to_point_on_circle[1],
      x2: @entity.x + vector_to_point_on_circle[0] + vector_to_front_of_unit[0],
      y2: @entity.y + vector_to_point_on_circle[1] + vector_to_front_of_unit[1],
      x3: @entity.x - vector_to_point_on_circle[0] + vector_to_front_of_unit[0],
      y3: @entity.y - vector_to_point_on_circle[1] + vector_to_front_of_unit[1],
      x4: @entity.x - vector_to_point_on_circle[0],
      y4: @entity.y - vector_to_point_on_circle[1],
      color: @entity.player.color,
      z: 2,
    )
    @line ||= @renderer.line(
      x1: @entity.x,
      y1: @entity.y,
      x2: @entity.x + vector_to_front_of_unit[0],
      y2: @entity.y + vector_to_front_of_unit[1],
      width: RADIUS / 2.0,
      color: "black",
      z: 2,
    )
  end

  def render
    super

    @circle.x = @entity.x
    @circle.y = @entity.y

    vector_to_point_on_circle = vector_from_magnitude_and_direction(RADIUS, @entity.direction + Math::PI / 2)
    vector_to_front_of_unit = vector_from_magnitude_and_direction(RADIUS + 2, @entity.direction)
    @square.x1 = @entity.x + vector_to_point_on_circle[0]
    @square.y1 = @entity.y + vector_to_point_on_circle[1]
    @square.x2 = @entity.x + vector_to_point_on_circle[0] + vector_to_front_of_unit[0]
    @square.y2 = @entity.y + vector_to_point_on_circle[1] + vector_to_front_of_unit[1]
    @square.x3 = @entity.x - vector_to_point_on_circle[0] + vector_to_front_of_unit[0]
    @square.y3 = @entity.y - vector_to_point_on_circle[1] + vector_to_front_of_unit[1]
    @square.x4 = @entity.x - vector_to_point_on_circle[0]
    @square.y4 = @entity.y - vector_to_point_on_circle[1]

    @line.x1 = @entity.x
    @line.y1 = @entity.y
    @line.x2 = @entity.x + vector_to_front_of_unit[0]
    @line.y2 = @entity.y + vector_to_front_of_unit[1]
  end

  def derender
    super
    @circle&.remove
    @square&.remove
    @line&.remove
  end
end
