require_relative "./types/unit"

class GeneratorPresenter < UnitPresenter
  RADIUS = 10.0

  attr_reader :triangle, :label

  def prerender
    super
    top_left_corner = vector_from_magnitude_and_direction(RADIUS, Math::PI * 4.0 / 3.0)
    top_right_corner = vector_from_magnitude_and_direction(RADIUS, -Math::PI * 4.0 / 3.0)
    bottom_corner = vector_from_magnitude_and_direction(RADIUS, 0)
    @triangle ||= @renderer.triangle(
      x1: @entity.x + top_left_corner[0],
      y1: @entity.y + top_left_corner[1],
      x2: @entity.x + top_right_corner[0],
      y2: @entity.y + top_right_corner[1],
      x3: @entity.x + bottom_corner[0],
      y3: @entity.y + bottom_corner[1],
      color: "white",
      z: 2,
    )
    @label ||= @renderer.text(
      "+#{@entity.capacity}",
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
    @triangle.color = @entity.player.color
    @triangle.opacity = @entity.built? ? 1.0 : (0.2 + @entity.healthyness * 0.7)
    if @entity.built?
      @label.add
      @label.color = @entity.player.color
    else
      @label.remove
    end
  end

  def derender
    super
    @triangle&.remove
    @label&.remove
  end
end
