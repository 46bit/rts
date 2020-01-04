require_relative './render_shape'

class Renderer
  attr_reader :screen_size, :world_size, :scale_multiplier, :shapes

  def initialize(screen_size, world_size)
    @screen_size = screen_size
    @world_size = world_size
    @centre_x = 0 # world_size.to_f #/ 2.0
    @centre_y = 0 # world_size.to_f #/ 2.0
    @zoom_multiplier = 1.0
    @shapes = {}
    recalculate_scale_multiplier
  end

  def recalculate_scale_multiplier
    @scale_multiplier = @screen_size.to_f / @world_size * @zoom_multiplier
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
    @zoom_multiplier *= in_or_out ? 1.1 : 0.9
    recalculate_scale_multiplier
    recompute_shapes
  end

  def recompute_shapes
    @shapes.values.each(&:recompute)
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

  def attach(shape)
    @shapes[shape.object_id] = shape
  end

  def detach(shape)
    @shapes.delete(shape.object_id)
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
end
