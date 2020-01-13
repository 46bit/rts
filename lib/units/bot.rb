require_relative "../entities/engineer"

class Bot < Engineer
  RADIUS = 5.0

  attr_reader :circle, :line

  def initialize(renderer, position, player, direction: rand * Math::PI * 2, built: true)
    super(
      renderer,
      position,
      player,
      max_health: 10,
      built: built,
      direction: direction,
      movement_rate: 0.1,
      turn_rate: 4.0 / 3.0,
      collision_radius: 5.0,
      production_range: 25.0,
      prerender_constructions: true,
    )
    prerender unless HEADLESS || !built
  end

  def kill
    super
    return if HEADLESS

    @circle.remove if @circle
    @line.remove if @line
  end

  def prerender
    super
    @circle ||= @renderer.circle(
      x: @position[0] - (RADIUS / 2.0),
      y: @position[1] - (RADIUS / 2.0),
      radius: RADIUS,
      color: @player.color,
      segments: 20,
      z: 2,
    )
    v = vector_from_magnitude_and_direction(RADIUS, @direction)
    @line ||= @renderer.line(
      x1: @position[0],
      y1: @position[1],
      x2: @position[0] + v[0],
      y2: @position[1] + v[1],
      width: 3,
      color: "black",
      z: 2,
    )
  end

  def render
    return if @dead

    super

    @circle.x = @position[0]
    @circle.y = @position[1]

    v = vector_from_magnitude_and_direction(RADIUS, @direction)
    @line.x1 = @position[0]
    @line.y1 = @position[1]
    @line.x2 = @position[0] + v[0]
    @line.y2 = @position[1] + v[1]
  end
end
