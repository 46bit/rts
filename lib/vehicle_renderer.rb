require_relative './vehicle'
require_relative './utils'

class VehicleRenderer < Vehicle
  attr_reader :circle, :line

  def initialize(*)
    super

    @circle = Circle.new(
      x: (@position[0] - 2.5) * @scale_factor,
      y: (@position[1] - 2.5) * @scale_factor,
      radius: @scale_factor * 5,
      color: 'white',
      segments: 20,
      z: 2,
    )
    v = vector_from_magnitude_and_direction(@scale_factor * 5.0, @direction)
    @line = Line.new(
      x1: @position[0] * @scale_factor,
      y1: @position[1] * @scale_factor,
      x2: @position[0] * @scale_factor + v[0],
      y2: @position[1] * @scale_factor + v[1],
      width: 3 * @scale_factor, # FIXME: Base this on @scale_factor
      color: 'black',
      z: 2,
    )
  end

  def color
    @circle.color
  end

  def color=(color)
    @circle.color = color
  end

  def kill
    super
    @circle.remove
    @line.remove
  end

  def collided?(other_vehicle)
    distance = (@position - other_vehicle.position).magnitude
    distance <= 10.0
  end

  def tick(*)
    return if @dead

    super

    @circle.x = @position[0] * @scale_factor
    @circle.y = @position[1] * @scale_factor

    v = vector_from_magnitude_and_direction(@scale_factor * 5.0, @direction)
    @line.x1 = @position[0] * @scale_factor
    @line.y1 = @position[1] * @scale_factor
    @line.x2 = @position[0] * @scale_factor + v[0]
    @line.y2 = @position[1] * @scale_factor + v[1]
  end
end
