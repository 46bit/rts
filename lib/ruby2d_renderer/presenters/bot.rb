require_relative "./types/unit"

class BotPresenter < EngineerPresenter
  RADIUS = 5.0

  attr_reader :circle, :line

  def prerender
    super
    @circle ||= @renderer.circle(
      x: @entity.x - (RADIUS / 2.0),
      y: @entity.y - (RADIUS / 2.0),
      radius: RADIUS,
      color: @entity.player.color,
      segments: 20,
      z: 2,
    )
    v = vector_from_magnitude_and_direction(RADIUS, @entity.direction)
    @line ||= @renderer.line(
      x1: @entity.x,
      y1: @entity.y,
      x2: @entity.x + v[0],
      y2: @entity.y + v[1],
      width: 3,
      color: "black",
      z: 2,
    )
  end

  def render
    super

    @circle.x = @entity.x
    @circle.y = @entity.y

    v = vector_from_magnitude_and_direction(RADIUS, @entity.direction)
    @line.x1 = @entity.x
    @line.y1 = @entity.y
    @line.x2 = @entity.x + v[0]
    @line.y2 = @entity.y + v[1]
  end

  def derender
    super
    @circle.remove if @circle
    @line.remove if @line
  end
end
