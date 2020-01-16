require_relative "./types/engineer"

class CommanderPresenter < EngineerPresenter
  RADIUS = 7.0

  attr_reader :star, :circle, :line

  def prerender
    super
    @star ||= @renderer.star(
      x: @entity.x,
      y: @entity.y,
      radius: RADIUS,
      color: @entity.player.color,
      z: 1,
    )
    @circle ||= @renderer.circle(
      x: @entity.x,
      y: @entity.y,
      radius: RADIUS / 2.0,
      color: "black",
      z: 2,
    )
    v = vector_from_magnitude_and_direction(RADIUS * 1.5, @entity.direction)
    @line ||= @renderer.line(
      x1: @entity.x,
      y1: @entity.y,
      x2: @entity.x + v[0],
      y2: @entity.y + v[1],
      width: 4,
      color: "black",
      z: 2,
    )
  end

  def render
    super

    @star.x = @entity.x
    @star.y = @entity.y

    @circle.x = @entity.x
    @circle.y = @entity.y

    v = vector_from_magnitude_and_direction(RADIUS * 1.5, @entity.direction)
    @line.x1 = @entity.x
    @line.y1 = @entity.y
    @line.x2 = @entity.x + v[0]
    @line.y2 = @entity.y + v[1]
  end

  def derender
    super
    @star&.remove
    @circle&.remove
    @line&.remove
  end
end
