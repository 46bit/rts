module Engineerable
  attr_reader :production_range, :prerender_constructions, :unit, :energy_provided

  def initialize_engineerable(production_range: 0, prerender_constructions: true)
    @production_range = production_range
    @prerender_constructions = prerender_constructions
    @unit = nil
    @energy_provided = 0
  end

  def produce(unit_class, position: @position, **kargs)
    # FIXME: Do override what's in production
    return unless @unit.nil?
    return false unless within_production_range?(position)
    construction = @player.constructions.select { |u| u.class == unit_class && u.position == position }[0]
    if construction
      @unit = construction
    else
      @unit = unit_class.new(
        @renderer,
        position,
        @player,
        built: false,
        **kargs,
      )
      @unit.prerender if @prerender_constructions
      @player.constructions << @unit
    end
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

  def within_production_range?(position)
    (position - @position).magnitude <= @production_range
  end

  def energy_provided=(energy_provided)
    @energy_provided = energy_provided
  end

  def update_production(prerender: true)
    return if @unit.nil?

    if @unit.dead?
      @unit = nil
      return
    end

    @unit.repair(@energy_provided * @unit.health_per_unit_cost)
    if @unit.built?
      @unit = nil
    end

    # FIXME: Reimplement excess_build_capacity when I start using it
    # excess_build_capacity = [@unit_investment - UNIT_CONSTRUCTION_COST, 0].max
  end
end
