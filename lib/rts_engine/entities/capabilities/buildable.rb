require_relative "./killable"

module Buildable
  include Killable

  attr_reader :built, :cost, :delay_before_building

  def initialize_buildable(built: false, max_health:, health: nil, cost:, delay_before_building: 20)
    health = built ? max_health : 0.0 if health.nil?
    initialize_killable(max_health: max_health, health: health)
    @built = built
    @cost = cost
    @delay_before_building = delay_before_building
  end

  def built?
    @built
  end

  def under_construction?
    !@built
  end

  def health_per_unit_cost
    @max_health.to_f / @cost
  end

  def repair(*)
    if @delay_before_building > 0
      @delay_before_building -= 1
      return false
    end
    super
    @built ||= !damaged?
  end
end
