# FIXME: Make the parameters editable
class RenderStar
  attr_reader :square, :diagonal_square

  def initialize(renderer, x:, y:, radius:, color:, opacity: nil, z: nil)
    @radius = radius
    @square = renderer.square(
      x: x - @radius,
      y: y - @radius,
      size: @radius * 2,
      color: color,
      opacity: opacity,
      z: z,
    )
    distance_to_corners = Math.sqrt(2) * @radius
    @diagonal_square = renderer.quad(
      x1: x,
      y1: y - distance_to_corners,
      x2: x + distance_to_corners,
      y2: y,
      x3: x,
      y3: y + distance_to_corners,
      x4: x - distance_to_corners,
      y4: y,
      color: color,
      opacity: opacity,
      z: z,
    )
  end

  def opacity=(opacity)
    @square.opacity = opacity
    @diagonal_square.opacity = opacity
  end

  def x=(x)
    @square.x = x - @radius
    distance_to_corners = Math.sqrt(2) * @radius
    @diagonal_square.x1 = x
    @diagonal_square.x2 = x + distance_to_corners
    @diagonal_square.x3 = x
    @diagonal_square.x4 = x - distance_to_corners
  end

  def y=(y)
    @square.y = y - @radius
    distance_to_corners = Math.sqrt(2) * @radius
    @diagonal_square.y1 = y - distance_to_corners
    @diagonal_square.y2 = y
    @diagonal_square.y3 = y + distance_to_corners
    @diagonal_square.y4 = y
  end

  def recompute
    @square.recompute
    @diagonal_square.recompute
  end

  def remove
    @square.remove
    @diagonal_square.remove
  end

  def add
    @square.add
    @diagonal_square.add
  end
end
