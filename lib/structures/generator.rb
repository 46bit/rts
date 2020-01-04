require_relative './structure'

class Generator < Structure
  def self.from_config(generator_config, scale_factor)
    Generator.new(
      Vector[
        generator_config["x"],
        generator_config["y"]
      ],
      scale_factor: scale_factor,
      capacity: generator_config["capacity"],
    )
  end

  attr_reader :capacity, :triangle, :target_circle, :label

  def initialize(*args, capacity: 1.0, **kargs)
    super(*args, **kargs)
    @capacity = capacity

    prerender unless HEADLESS
  end

  def collided?(object)
    distance = (object.position - @position).magnitude
    case object
    when Vehicle
      return distance <= 4 + Vehicle::COLLISION_RADIUS
    else
      raise "unexpected collision query for object with class #{object.class}"
    end
  end

  def prerender
    @triangle = Triangle.new(
      x1: scale(@position[0]),
      y1: scale(@position[1] - 6.5),
      x2: scale(@position[0] + 6.5),
      y2: scale(@position[1] + 6.5),
      x3: scale(@position[0] - 6.5),
      y3: scale(@position[1] + 6.5),
      color: 'white',
      z: 1,
    )
    @target_circle = Circle.new(
      x: scale(@position[0]),
      y: scale(@position[1]),
      radius: scale(9),
      opacity: 0,
      z: 0,
    )
    @label = Text.new(
      @capacity.to_s,
      x: scale(@position[0]),
      y: scale(@position[1] + 8.5),
      size: scale(10),
      color: 'white',
      z: 1,
    )
    @label.x -= @label.width / 2
  end

  def render
    @triangle.color = occupied? ? @player.color : 'white'
  end
end
