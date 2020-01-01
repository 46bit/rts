require_relative './generator'

class GeneratorRenderer < Generator
  attr_reader :triangle, :target_circle

  def initialize(*args, scale_factor: 1.0, **kargs)
    super(*args, **kargs)

    @triangle = Triangle.new(
      x1: @position[0] * scale_factor,
      y1: (@position[1] - 6.5) * scale_factor,
      x2: (@position[0] + 6.5) * scale_factor,
      y2: (@position[1] + 6.5) * scale_factor,
      x3: (@position[0] - 6.5) * scale_factor,
      y3: (@position[1] + 6.5) * scale_factor,
      color: 'white',
      z: 1,
    )
    @target_circle = Circle.new(
      x: @position[0] * scale_factor,
      y: @position[1] * scale_factor,
      radius: scale_factor * 9,
      opacity: 0,
      z: 0,
    )
  end

  def tick
    super
    @triangle.color = occupied? ? @player_owner.color : 'white'
  end

  def contains?(x, y)
    @target_circle.contains?(x, y)
  end
end
