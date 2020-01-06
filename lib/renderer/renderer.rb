require_relative './shapes'
require_relative './star'
require_relative './teardrop'
require_relative './camera'

class Renderer
  attr_reader :screen_size, :world_size, :scale_multiplier, :shapes
  attr_accessor :centre_x, :centre_y, :zoom_multiplier

  def initialize(screen_size, world_size)
    @screen_size = screen_size
    @world_size = world_size
    @centre_x = 0
    @centre_y = 0
    @shapes = {}
    @zoom_multiplier = 1.0
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

  def star(**kargs)
    RenderStar.new(self, **kargs)
  end

  def teardrop(**kargs)
    RenderTeardrop.new(self, **kargs)
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

  def recalculate_scale_multiplier
    @scale_multiplier = @screen_size.to_f / @world_size * @zoom_multiplier
  end

  def recompute_shapes
    @shapes.values.each(&:recompute)
  end
end
