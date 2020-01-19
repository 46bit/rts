module Engineerable
  attr_reader :production_range, :unit, :energy_provided

  def initialize_engineerable(production_range: 0)
    @production_range = production_range
    @unit = nil
    @energy_provided = 0
  end

  def start_constructing(unit_class, build_at, **kargs)
    position = build_at.class == Vector ? build_at : build_at.position
    # FIXME: Do override what's in production
    return true unless @unit.nil?
    raise "trying to produce something outside of production range" unless within_production_range?(position)

    existing_construction = @player.constructions.select { |u| u.is_a?(unit_class) && u.position == position }[0]
    if existing_construction
      @unit = existing_construction
    else
      @unit = unit_class.new(
        @renderer,
        build_at,
        @player,
        built: false,
        **kargs,
      )
      @player.constructions << @unit
    end
    true
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

  def update_production
    return if @unit.nil?

    if @unit.dead?
      @unit = nil
      return
    end

    # FIXME: Stop using energy if nothing is built
    if within_production_range?(@unit.position)
      @unit.repair(@energy_provided * @unit.health_per_unit_cost)
    end

    if @unit.built?
      @unit = nil
    end
  end
end
