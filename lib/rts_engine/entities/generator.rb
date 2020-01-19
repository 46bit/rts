require_relative "../../utils"
require_relative "./types/structure"
require_relative "./types/projectile"

class Generator < Structure
  attr_reader :capacity

  def initialize(renderer, power_source, player, built: true, capacity: 1)
    raise "trying to build generator on something other than a power source: #{power_source}" if power_source.class != PowerSource

    super(renderer, power_source.position, player, max_health: 60, built: built, health: built ? 60 : 0, collision_radius: 5)
    @power_source = power_source
    @capacity = capacity
    power_source.structure = self
  end
end
