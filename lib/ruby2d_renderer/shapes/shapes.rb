require_relative "./ruby2d_shape"
require_relative "./star"
require_relative "./teardrop"
require_relative "./icon"

class RenderCircle < Ruby2DShape
  SHAPE = Circle
  attr_shape_x :x
  attr_shape_y :y
  attr_shape_distance :radius
  attr_shape_static :z, :sectors, :color, :opacity
end

class RenderTriangle < Ruby2DShape
  SHAPE = Triangle
  attr_shape_x :x1, :x2, :x3
  attr_shape_y :y1, :y2, :y3
  attr_shape_static :z, :color, :opacity
end

class RenderSquare < Ruby2DShape
  SHAPE = Square
  attr_shape_x :x
  attr_shape_y :y
  attr_shape_distance :size
  attr_shape_static :z, :color, :opacity
end

class RenderQuad < Ruby2DShape
  SHAPE = Quad
  attr_shape_x :x1, :x2, :x3, :x4
  attr_shape_y :y1, :y2, :y3, :y4
  attr_shape_static :z, :color, :opacity
end

class RenderLine < Ruby2DShape
  SHAPE = Line
  attr_shape_x :x1, :x2
  attr_shape_y :y1, :y2
  attr_shape_distance :width
  attr_shape_static :z, :color, :opacity
end

class RenderText < Ruby2DShape
  SHAPE = Text
  DEFAULT_FONT_NAME = Font.default

  attr_shape_x :x
  attr_shape_y :y
  # FIXME: size, width and height are readonly
  attr_shape_static :size, :z, :color, :opacity, :width, :height, :text

  def initialize(*args, **kargs)
    # FIXME: The underlying problem here is actually that Simple2D doesn't deduplicate font file
    # descriptors at all. That's something that I should go fix.
    kargs[:font] ||= DEFAULT_FONT_NAME
    super(*args, **kargs)
    @align_centre = false
    @align_middle = false
  end

  def align_centre
    @align_centre = true
    @shape.x = @renderer.apply(:x, @shape_values[:x][:x]) - @shape.width / 2.0
  end

  def align_middle
    @align_middle = true
    @shape.y = @renderer.apply(:y, @shape_values[:y][:y]) - @shape.height / 2.0
  end

  def recompute(*)
    super
    align_centre if @align_centre
    align_middle if @align_middle
  end
end
