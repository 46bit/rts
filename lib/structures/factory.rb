require_relative './buildable'
require_relative '../vehicles/bot'
require_relative '../vehicles/tank'

class Factory < BuildableStructure
  MAX_HEALTH = 120
  COLLISION_RADIUS = 15
  UNIT_CONSTRUCTION_COST = 100

  attr_reader :unit, :unit_investment
  attr_reader :outline, :square, :progress_square, :health_bar

  def initialize(*)
    super
    @construction = nil

    prerender unless HEADLESS
  end

  def construct
    return unless @built
    if @unit.nil?
      # FIXME: Player must choose unit composition
      @unit = rand > 0.5 ? Tank : Bot
      @unit_investment = 0
    end
  end

  def unit_progress
    @unit_investment.to_f / UNIT_CONSTRUCTION_COST
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

    @unit_investment += build_capacity
    excess_build_capacity = [@unit_investment - UNIT_CONSTRUCTION_COST, 0].max

    unit = nil
    if @unit_investment >= UNIT_CONSTRUCTION_COST && can_produce
      unit = @unit.new(
        @position,
        @player,
        @renderer,
      )
      @unit = nil
    end

    return excess_build_capacity, unit
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
