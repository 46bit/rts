require_relative './render_shape'

class Renderer
  attr_reader :screen_size, :world_size, :scale_multiplier, :shapes

  def initialize(screen_size, world_size)
    @screen_size = screen_size
    @world_size = world_size
    @centre_x = 0
    @centre_y = 0
    @zoom_multiplier = 1.0
    @shapes = {}
    recalculate_scale_multiplier
  end

  def circle(**kargs)
    RenderCircle.new(self, **kargs)
  end

  def triangle(**kargs)
    RenderTriangle.new(self, **kargs)
  end

  def square(**kargs)
    RenderSquare.new(self, **kargs)
  end

  def quad(**kargs)
    RenderQuad.new(self, **kargs)
  end

  def line(**kargs)
    RenderLine.new(self, **kargs)
  end

  def text(text, **kargs)
    RenderText.new(self, text, **kargs)
  end

  def move(dx, dy)
    @centre_x += dx
    @centre_y += dy
    recompute_shapes
  end

  def zoom(in_or_out)
    centre_of_screen_before_x = unapply(:x, @screen_size / 2)
    centre_of_screen_before_y = unapply(:y, @screen_size / 2)
    @zoom_multiplier *= in_or_out ? 1.1 : 0.9
    recalculate_scale_multiplier
    centre_of_screen_after_x = unapply(:x, @screen_size / 2)
    centre_of_screen_after_y = unapply(:y, @screen_size / 2)
    @centre_x += (centre_of_screen_before_x - centre_of_screen_after_x)
    @centre_y += (centre_of_screen_before_y - centre_of_screen_after_y)
    recompute_shapes
  end

  def apply(type, value)
    case type
    when :distance
      value * @scale_multiplier
    when :x
      (value - @centre_x) * @scale_multiplier
    when :y
      (value - @centre_y) * @scale_multiplier
    else
      raise "unknown value type to render: #{type}"
    end
  end

  def unapply(type, value)
    case type
    when :distance
      value / @scale_multiplier
    when :x
      value / @scale_multiplier + @centre_x
    when :y
      value / @scale_multiplier + @centre_y
    else
      raise "unknown value type to render: #{type}"
    end
  end

  def attach(shape)
    @shapes[shape.object_id] = shape
  end

  def detach(shape)
    @shapes.delete(shape.object_id)
  end

protected

  def recalculate_scale_multiplier
    @scale_multiplier = @screen_size.to_f / @world_size * @zoom_multiplier
  end

  def recompute_shapes
    @shapes.values.each(&:recompute)
  end
end

class RenderCircle < RenderShape
  SHAPE = Circle
  attr_shape_x :x
  attr_shape_y :y
  attr_shape_distance :radius
  attr_shape_static :z, :sectors, :color, :opacity
end

class RenderTriangle < RenderShape
  SHAPE = Triangle
  attr_shape_x :x1, :x2, :x3
  attr_shape_y :y1, :y2, :y3
  attr_shape_static :z, :color, :opacity
end

class RenderSquare < RenderShape
  SHAPE = Square
  attr_shape_x :x
  attr_shape_y :y
  attr_shape_distance :size
  attr_shape_static :z, :color, :opacity
end

class RenderQuad < RenderShape
  SHAPE = Quad
  attr_shape_x :x1, :x2, :x3, :x4
  attr_shape_y :y1, :y2, :y3, :y4
  attr_shape_static :z, :color, :opacity
end

class RenderLine < RenderShape
  SHAPE = Line
  attr_shape_x :x1, :x2
  attr_shape_y :y1, :y2
  attr_shape_distance :width
  attr_shape_static :z, :color, :opacity
end

class RenderText < RenderShape
  SHAPE = Text
  attr_shape_x :x
  attr_shape_y :y
  attr_shape_distance :size
  # FIXME: width and height are readonly
  attr_shape_static :z, :color, :opacity, :width, :height, :text

  def align_centre
    @align_centre = true
    @shape.x -= @shape.width / 2.0
  end

  def align_middle
    @align_middle = true
    @shape.y -= @shape.height / 2.0
  end

  def recompute
    super
    align_centre if @align_centre
    align_middle if @align_middle
  end
end
