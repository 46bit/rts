require_relative '../entities/structure'
require_relative '../entities/capabilities/engineerable'

class Factory < Structure
  include Engineerable

  attr_reader :outline, :square, :progress_square, :health_bar

  def initialize(renderer, position, player, built: true)
    super(renderer, position, player, max_health: 120, built: built, health: built ? 120 : 0, collision_radius: 15)
    initialize_engineerable
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

  def update(energy, can_complete: true)
    return if dead? || under_construction? || !producing?
    return update_production(energy, can_complete: can_complete)
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
    @progress_square.opacity = @unit.nil? ? 0.0 : (0.1 + production_progress * 0.9)

    if damaged?
      @health_bar.add
    else
      @health_bar.remove
    end
  end
end
