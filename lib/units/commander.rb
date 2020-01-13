require_relative "../entities/engineer"

class Commander < Engineer
  RADIUS = 7.0

  attr_reader :star, :circle, :line, :health_bar

  def initialize(renderer, position, player, direction: rand * Math::PI * 2)
    super(
      renderer,
      position,
      player,
      max_health: 1000,
      built: true,
      direction: direction,
      movement_rate: 0.03,
      turn_rate: 2.0 / 3.0,
      collision_radius: 8.0,
      production_range: 35.0,
      prerender_constructions: true,
    )
    prerender unless HEADLESS || !built
  end

  def kill
    super
    return if HEADLESS

    @star.remove if @star
    @circle.remove if @circle
    @line.remove if @line
    @health_bar.remove if @health_bar
  end

  def prerender
    super
    @star ||= @renderer.star(
      x: @position[0],
      y: @position[1],
      radius: RADIUS,
      color: @player.color,
      z: 1,
    )
    @circle ||= @renderer.circle(
      x: @position[0],
      y: @position[1],
      radius: RADIUS / 2.0,
      color: "black",
      z: 2,
    )
    v = vector_from_magnitude_and_direction(RADIUS * 1.5, @direction)
    @line ||= @renderer.line(
      x1: @position[0],
      y1: @position[1],
      x2: @position[0] + v[0],
      y2: @position[1] + v[1],
      width: 4,
      color: "black",
      z: 2,
    )
    @health_bar ||= @renderer.line(
      x1: @position[0] - RADIUS,
      y1: @position[1] + RADIUS + 3,
      x2: @position[0] + RADIUS,
      y2: @position[1] + RADIUS + 3,
      width: 1.5,
      color: @player.color,
      z: 2,
    )
  end

  def render
    return if @dead

    super

    @star.x = @position[0]
    @star.y = @position[1]

    @circle.x = @position[0]
    @circle.y = @position[1]

    v = vector_from_magnitude_and_direction(RADIUS * 1.5, @direction)
    @line.x1 = @position[0]
    @line.y1 = @position[1]
    @line.x2 = @position[0] + v[0]
    @line.y2 = @position[1] + v[1]

    @health_bar.x1 = @position[0] - RADIUS
    @health_bar.y1 = @position[1] + RADIUS + 3
    @health_bar.x2 = @position[0] - RADIUS + 2 * RADIUS * healthyness
    @health_bar.y2 = @position[1] + RADIUS + 3
    @health_bar.width = healthyness > 0.5 ? 1.5 : 2
    if damaged?
      @health_bar.add
    else
      @health_bar.remove
    end
  end
end
