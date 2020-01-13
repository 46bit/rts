require_relative "../entities/location"

class Generator < Location
  def self.from_config(generator_config, renderer)
    Generator.new(
      renderer,
      Vector[
        generator_config["x"],
        generator_config["y"]
      ],
      capacity: generator_config["capacity"],
    )
  end

  RADIUS = 7.0

  attr_reader :capacity, :triangle, :target_circle, :label

  def initialize(renderer, position, player: nil, capacity:)
    super(renderer, position, player: player, collision_radius: RADIUS)
    @capacity = capacity
    prerender unless HEADLESS
  end

  def prerender
    top_corner = vector_from_magnitude_and_direction(RADIUS, -Math::PI)
    bottom_right_corner = vector_from_magnitude_and_direction(RADIUS, -Math::PI / 3.0)
    bottom_left_corner = vector_from_magnitude_and_direction(RADIUS, Math::PI / 3.0)
    @triangle ||= @renderer.triangle(
      x1: @position[0] + top_corner[0],
      y1: @position[1] + top_corner[1],
      x2: @position[0] + bottom_right_corner[0],
      y2: @position[1] + bottom_right_corner[1],
      x3: @position[0] + bottom_left_corner[0],
      y3: @position[1] + bottom_left_corner[1],
      color: "white",
      z: 1,
    )
    @target_circle ||= @renderer.circle(
      x: @position[0],
      y: @position[1],
      radius: RADIUS + 2,
      opacity: 0,
      z: 0,
    )
    @label ||= @renderer.text(
      @capacity.to_s,
      x: @position[0],
      y: @position[1] + RADIUS + 2.0,
      size: 10,
      color: "white",
      z: 1,
    )
    @label.align_centre
  end

  def render
    @triangle.color = occupied? ? @player.color : "white"
  end
end
