require_relative './factory'

class FactoryRenderer < Factory
  attr_reader :color
  attr_reader :outline, :square, :progress_square

  def initialize(*args, color: 'white', **kargs)
    @color = color
    kargs[:vehicle_class] ||= VehicleRenderer
    super(*args, **kargs)

    @outline = Square.new(
      x: (@position[0] - 9.5) * @scale_factor,
      y: (@position[1] - 9.5) * @scale_factor,
      size: @scale_factor * 19,
      color: color,
      z: 1,
    )
    @square = Square.new(
      x: (@position[0] - 7.5) * @scale_factor,
      y: (@position[1] - 7.5) * @scale_factor,
      size: @scale_factor * 15,
      color: 'black',
      z: 2,
    )
    @progress_square = Square.new(
      x: (@position[0] - 7.5) * @scale_factor,
      y: (@position[1] - 7.5) * @scale_factor,
      size: @scale_factor * 15,
      color: color,
      opacity: 0.0,
      z: 3,
    )
  end

  def tick(*)
    vehicle = super
    if @construction_progress.nil?
      @progress_square.opacity = 0.0
    else
      @progress_square.opacity = 0.1 + 0.9 * progress
    end
    return vehicle
  end
end
