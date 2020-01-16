require_relative "./types/location"

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

  attr_reader :capacity

  def initialize(renderer, position, capacity:)
    super(renderer, position, collision_radius: 7)
    @capacity = capacity
  end
end
