require_relative '../entities/structure'
require_relative './bot'
require_relative './tank'

class Factory < Structure
  UNIT_HEALTH_PER_BUILD_CAPACITY = 0.1

  attr_reader :unit, :unit_investment
  attr_reader :outline, :square, :progress_square, :health_bar

  def initialize(renderer, position, player, built: true)
    super(renderer, position, player, max_health: 120, built: built, health: built ? 120 : 0, collision_radius: 15)
    @unit = nil
    prerender unless HEADLESS
  end

  def construct(unit_class)
    return unless @built
    if @unit.nil?
      @unit = unit_class.new(
        @renderer,
        @position,
        @player,
        built: false,
      )
      @unit_investment = 0
    end
  end

  def producing?
    !@unit.nil?
  end

  def energy_drain
    producing? ? 20 : 0
  end

  def unit_progress
    @unit.healthyness
  end

  def kill
    super
    unless HEADLESS
      @outline.remove
      @square.remove
      @progress_square.remove
      @health_bar.remove
    end
  end

  def update(build_capacity, can_produce: true)
    return if @dead || !@built || !@unit

    @unit.repair(build_capacity * UNIT_HEALTH_PER_BUILD_CAPACITY)
    # FIXME: Reimplement excess_build_capacity when I start using it
    # excess_build_capacity = [@unit_investment - UNIT_CONSTRUCTION_COST, 0].max
    if can_produce && @unit.built?
      built_unit = @unit
      built_unit.prerender
      @unit = nil
      return 0.0, built_unit
    end
    return 0.0, nil
  end

  def prerender
    @outline = @renderer.square(
      x: @position[0] - 9.5,
      y: @position[1] - 9.5,
      size: 19,
      color: @player.color,
      z: 1,
    )
    @square = @renderer.square(
      x: @position[0] - 7.5,
      y: @position[1] - 7.5,
      size: 15,
      color: 'black',
      z: 2,
    )
    @progress_square = @renderer.square(
      x: @position[0] - 7.5,
      y: @position[1] - 7.5,
      size: 15,
      color: @player.color,
      opacity: 0.0,
      z: 3,
    )
    @health_bar = @renderer.line(
      x1: @position[0] - 9.5,
      y1: @position[1] + 11,
      x2: @position[0] + 9.5,
      y2: @position[1] + 11,
      width: 1.5,
      color: @player.color,
      z: 2,
    )
  end

  def render
    @health_bar.x2 = @position[0] - 9.5 + 19 * healthyness
    @health_bar.width = healthyness > 0.5 ? 1.5 : 2

    @outline.opacity = @built ? 1.0 : (0.2 + healthyness * 0.8)
    @progress_square.opacity = @unit.nil? ? 0.0 : (0.1 + unit_progress * 0.9)

    if damaged?
      @health_bar.add
    else
      @health_bar.remove
    end
  end
end
