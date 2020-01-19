class SimpleCamera
  attr_reader :renderer

  def initialize(renderer)
    @renderer = renderer
  end

  def reset
    @renderer.centre_x = 0
    @renderer.centre_y = 0
    @renderer.zoom_multiplier = 1.0
    @renderer.recalculate_scale_multiplier
    @renderer.recompute_shapes
  end

  def move(dx, dy)
    @renderer.centre_x += dx
    @renderer.centre_y += dy
    @renderer.recompute_shapes
  end

  def zoom(in_or_out)
    centre_of_screen_before_x = @renderer.unapply(:x, @renderer.screen_size / 2)
    centre_of_screen_before_y = @renderer.unapply(:y, @renderer.screen_size / 2)

    @renderer.zoom_multiplier *= in_or_out ? 1.03 : 0.97
    @renderer.recalculate_scale_multiplier

    centre_of_screen_after_x = @renderer.unapply(:x, @renderer.screen_size / 2)
    centre_of_screen_after_y = @renderer.unapply(:y, @renderer.screen_size / 2)
    @renderer.centre_x += (centre_of_screen_before_x - centre_of_screen_after_x)
    @renderer.centre_y += (centre_of_screen_before_y - centre_of_screen_after_y)

    @renderer.recompute_shapes
  end
end
