require_relative "./types/entity"

class GeneratorPresenter < EntityPresenter
  RADIUS = 7.0

  attr_reader :triangle, :label

  def prerender
    super
    top_corner = vector_from_magnitude_and_direction(RADIUS, -Math::PI)
    bottom_right_corner = vector_from_magnitude_and_direction(RADIUS, -Math::PI / 3.0)
    bottom_left_corner = vector_from_magnitude_and_direction(RADIUS, Math::PI / 3.0)
    @triangle ||= @renderer.triangle(
      x1: @entity.x + top_corner[0],
      y1: @entity.y + top_corner[1],
      x2: @entity.x + bottom_right_corner[0],
      y2: @entity.y + bottom_right_corner[1],
      x3: @entity.x + bottom_left_corner[0],
      y3: @entity.y + bottom_left_corner[1],
      color: "white",
      z: 1,
    )
    @label ||= @renderer.text(
      @capacity.to_s,
      x: @entity.x,
      y: @entity.y + RADIUS + 2.0,
      size: 10,
      color: "white",
      z: 1,
    )
    # FIXME: Move this into a property when initialising @renderer.text(…)
    @label.align_centre
  end

  def render
    super
    @triangle.color = @entity.occupied? ? @entity.player.color : "white"
  end

  def derender
    super
    @triangle&.remove
    @label&.remove
  end
end
