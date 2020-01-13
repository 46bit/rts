require_relative "../entities/structure"
require_relative "../entities/capabilities/orderable"
require_relative "../entities/capabilities/engineerable"

FACTORY_ORDER_CALLBACKS = {
  NilClass => lambda do |_o|
    return nil
  end,
  BuildOrder => lambda { |o| build(o) },
}.freeze

class Factory < Structure
  include Orderable
  include Engineerable

  attr_reader :outline, :square, :progress_square, :health_bar

  def initialize(renderer, position, player, built: true)
    super(renderer, position, player, max_health: 120, built: built, health: built ? 120 : 0, collision_radius: 15)
    initialize_engineerable(prerender_constructions: false)
    initialize_orderable(FACTORY_ORDER_CALLBACKS)
    prerender unless HEADLESS
  end

  def produce(*)
    super if built?
  end

  def kill
    super
    unless @unit.nil?
      @unit.kill
      @unit = nil
    end
    unless HEADLESS
      @outline.remove if @outline
      @square.remove if @square
      @progress_square.remove if @progress_square
      @health_bar.remove if @health_bar
    end
  end

  def update
    return if dead?

    update_production
  end

  def prerender
    @outline ||= @renderer.square(
      x: @position[0] - 9.5,
      y: @position[1] - 9.5,
      size: 19,
      color: @player.color,
      z: 1,
    )
    @square ||= @renderer.square(
      x: @position[0] - 7.5,
      y: @position[1] - 7.5,
      size: 15,
      color: "black",
      z: 2,
    )
    @progress_square ||= @renderer.square(
      x: @position[0] - 7.5,
      y: @position[1] - 7.5,
      size: 15,
      color: @player.color,
      opacity: 0.0,
      z: 3,
    )
    @health_bar ||= @renderer.line(
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
    @progress_square.opacity = @unit.nil? ? 0.0 : (0.1 + production_progress * 0.9)

    if damaged?
      @health_bar.add
    else
      @health_bar.remove
    end
  end

protected

  def build(build_order)
    produce(build_order.unit_class)
    build_order
  end
end
