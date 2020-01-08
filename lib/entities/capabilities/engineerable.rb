module Engineerable
  attr_reader :unit

  def initialize_engineerable
    @unit = nil
  end

  def produce(unit_class, position: @position, **kargs)
    # FIXME: Do override what's in production
    return unless @unit.nil?
    @unit = unit_class.new(
      @renderer,
      position,
      @player,
      built: false,
      **kargs,
    )
  end

  def producing?
    !@unit.nil?
  end

  def production_progress
    @unit.healthyness
  end

  def energy_consumption
    producing? ? 20 : 0
  end

  def update_production(energy, can_complete: true)
    return if @unit.nil?

    @unit.repair(energy * @unit.health_per_unit_cost)
    # FIXME: Reimplement excess_build_capacity when I start using it
    # excess_build_capacity = [@unit_investment - UNIT_CONSTRUCTION_COST, 0].max
    return unless @unit.built? && can_complete

    built_unit = @unit
    built_unit.prerender
    @unit = nil
    return built_unit
  end
end
