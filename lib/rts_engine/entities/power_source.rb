require_relative "./types/location"

class PowerSource < Location
  def self.from_config(power_source_config, renderer)
    PowerSource.new(
      renderer,
      Vector[
        power_source_config["x"],
        power_source_config["y"]
      ],
      capacity: power_source_config["capacity"],
    )
  end

  attr_reader :capacity

  def initialize(renderer, position, capacity:)
    super(renderer, position, collision_radius: 7)
    @capacity = capacity
  end
end
