require_relative "../../utils"

class RenderIcon
  SIZE = 10.0

  attr_reader :renderer, :x, :y, :square, :label

  def initialize(renderer, x:, y:, character:, color:, opacity: nil, z: 9999)
    @renderer = renderer
    @x = x
    @y = y
    @square ||= @renderer.square(
      x: x - SIZE / 2,
      y: y - SIZE / 2,
      size: SIZE,
      color: color,
      opacity: opacity,
      z: z,
    )
    @renderer.detach(@square)
    @label ||= @renderer.text(
      character,
      x: x - SIZE / 2,
      y: y - SIZE / 2,
      size: SIZE,
      color: "white",
      z: z + 1,
    )
    @renderer.detach(@label)
    @renderer.attach(self)
    #@label.align_centre
    #@label.align_middle

    recompute
  end

  def x=(x)
    @x = x
    recompute
  end

  def y=(y)
    @y = y
    recompute
  end

  def recompute
    if @renderer.apply(:distance, SIZE) < 5
      add
      @square.size = @renderer.unapply(:distance, SIZE)
      @square.x = @x - @square.size / 2
      @square.y = @y - @square.size / 2
      @square.recompute
      @label.size = @renderer.unapply(:distance, SIZE)
      @label.x = @x
      @label.y = @y# - @label.size / 2.0
      @label.align_centre
      @label.align_middle
      @label.recompute
    else
      remove
    end
  end

  def remove
    @square.remove
    @label.remove
    @renderer.detach(self)
  end

  def add
    @square.add
    @label.add
    @renderer.attach(self)
  end
end
