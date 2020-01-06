require_relative '../entities/vehicle'

class Tank < Vehicle
  RADIUS = 8.0

  attr_reader :circle, :square, :line, :health_bar

  def initialize(renderer, position, player, direction: rand * Math::PI * 2, built: true)
    super(
      renderer,
      position,
      player,
      max_health: 200,
      built: built,
      direction: direction,
      movement_rate: 0.05,
      turn_rate: 4.0/6.0,
      collision_radius: 8.0,
    )
    prerender unless HEADLESS || !built
  end

  def kill
    super
    return if HEADLESS
    @circle.remove
    @square.remove
    @line.remove
    @health_bar.remove
  end

  def prerender
    @circle = @renderer.circle(
      x: @position[0],
      y: @position[1],
      radius: RADIUS,
      color: @player.color,
      segments: 20,
      z: 2,
    )
    vector_to_point_on_circle = vector_from_magnitude_and_direction(RADIUS, @direction + Math::PI / 2)
    vector_to_front_of_unit = vector_from_magnitude_and_direction(RADIUS + 2, @direction)
    @square = @renderer.quad(
      x1: @position[0] + vector_to_point_on_circle[0],
      y1: @position[1] + vector_to_point_on_circle[1],
      x2: @position[0] + vector_to_point_on_circle[0] + vector_to_front_of_unit[0],
      y2: @position[1] + vector_to_point_on_circle[1] + vector_to_front_of_unit[1],
      x3: @position[0] - vector_to_point_on_circle[0] + vector_to_front_of_unit[0],
      y3: @position[1] - vector_to_point_on_circle[1] + vector_to_front_of_unit[1],
      x4: @position[0] - vector_to_point_on_circle[0],
      y4: @position[1] - vector_to_point_on_circle[1],
      color: @player.color,
      z: 2,
    )
    @line = @renderer.line(
      x1: @position[0],
      y1: @position[1],
      x2: @position[0] + vector_to_front_of_unit[0],
      y2: @position[1] + vector_to_front_of_unit[1],
      width: RADIUS / 2.0,
      color: 'black',
      z: 2,
    )
    @health_bar = @renderer.line(
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

    @circle.x = @position[0]
    @circle.y = @position[1]

    vector_to_point_on_circle = vector_from_magnitude_and_direction(RADIUS, @direction + Math::PI / 2)
    vector_to_front_of_unit = vector_from_magnitude_and_direction(RADIUS + 2, @direction)
    @square.x1 = @position[0] + vector_to_point_on_circle[0]
    @square.y1 = @position[1] + vector_to_point_on_circle[1]
    @square.x2 = @position[0] + vector_to_point_on_circle[0] + vector_to_front_of_unit[0]
    @square.y2 = @position[1] + vector_to_point_on_circle[1] + vector_to_front_of_unit[1]
    @square.x3 = @position[0] - vector_to_point_on_circle[0] + vector_to_front_of_unit[0]
    @square.y3 = @position[1] - vector_to_point_on_circle[1] + vector_to_front_of_unit[1]
    @square.x4 = @position[0] - vector_to_point_on_circle[0]
    @square.y4 = @position[1] - vector_to_point_on_circle[1]

    @line.x1 = @position[0]
    @line.y1 = @position[1]
    @line.x2 = @position[0] + vector_to_front_of_unit[0]
    @line.y2 = @position[1] + vector_to_front_of_unit[1]

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
