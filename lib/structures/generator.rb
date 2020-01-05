require_relative './structure'

class Generator < Structure
  def self.from_config(generator_config, renderer)
    Generator.new(
      Vector[
        generator_config["x"],
        generator_config["y"]
      ],
      generator_config["capacity"],
      renderer,
    )
  end

  attr_reader :capacity, :triangle, :target_circle, :label

  def initialize(position, capacity, renderer)
    super(position, nil, renderer)
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
    @triangle = @renderer.triangle(
      x1: @position[0],
      y1: @position[1] - 6.5,
      x2: @position[0] + 6.5,
      y2: @position[1] + 6.5,
      x3: @position[0] - 6.5,
      y3: @position[1] + 6.5,
      color: 'white',
      z: 1,
    )
    @target_circle = @renderer.circle(
      x: @position[0],
      y: @position[1],
      radius: 9,
      opacity: 0,
      z: 0,
    )
    @label = @renderer.text(
      @capacity.to_s,
      x: @position[0],
      y: @position[1] + 8.5,
      size: 10,
      color: 'white',
      z: 1,
    )
    @label.x -= @label.width / 2
  end

  def render
    @triangle.color = occupied? ? @player.color : 'white'
  end
end
