require_relative "./killable"

module Buildable
  include Killable

  attr_reader :built, :cost

  def initialize_buildable(built: false, max_health:, health: nil, cost:)
    health = built ? max_health : 0.0 if health.nil?
    initialize_killable(max_health: max_health, health: health)
    @built = built
    @cost = cost
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
    super
    @built ||= !damaged?
  end
end
