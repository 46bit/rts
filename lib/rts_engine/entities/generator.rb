require_relative "../../utils"
require_relative "./types/structure"
require_relative "./types/projectile"

class Generator < Structure
  attr_reader :capacity
  attr_accessor :energy_provided

  def initialize(renderer, power_source, player, built: true, capacity: 1)
    raise "trying to build generator on something other than a power source: #{power_source}" if power_source.class != PowerSource

    super(renderer, power_source.position, player, max_health: 60, built: built, health: built ? 60 : 0, collision_radius: 5)
    power_source.structure = self
    @power_source = power_source
    @capacity = capacity

    @upgrading = false
    @energy_provided = 0
    @upgrade_energy_collected = 0
  end

  def upgrade
    @upgrading = true
  end

  def upgrading?
    @upgrading
  end

  def energy_consumption
    upgrading? ? 10 : 0
  end

  def update
    if @upgrading
      @upgrade_energy_collected += @energy_provided
      @energy_provided = 0 # FIXME: Improve the energy-providing APIs so this isn't required for clarity
      if @upgrade_energy_collected >= @capacity * 100
        # @capacity += 1.5
        @capacity *= 2.0
        @max_health += 30
        @health += 30
        @upgrading = false
        @upgrade_energy_collected = 0
      end
    end
  end
end
