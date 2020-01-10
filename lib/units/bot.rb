require_relative '../entities/vehicle'

class Bot < Vehicle
  include Engineerable

  RADIUS = 5.0
  SACRIFICIAL_REPAIR_VALUE = 20

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
      turn_rate: 4.0/3.0,
      collision_radius: 5.0,
      order_callbacks: DEFAULT_VEHICLE_ORDER_CALLBACKS.merge({
        RemoteBuildOrder => lambda { |o| remote_build(o) },
      })
    )
    initialize_engineerable
    prerender unless HEADLESS || !built
  end

  def kill
    super
    return if HEADLESS
    @circle.remove if @circle
    @line.remove if @line
  end

  def prerender
    @circle = @renderer.circle(
      x: @position[0] - (RADIUS / 2.0),
      y: @position[1] - (RADIUS / 2.0),
      radius: RADIUS,
      color: @player.color,
      segments: 20,
      z: 2,
    )
    v = vector_from_magnitude_and_direction(RADIUS, @direction)
    @line = @renderer.line(
      x1: @position[0],
      y1: @position[1],
      x2: @position[0] + v[0],
      y2: @position[1] + v[1],
      width: 3,
      color: 'black',
      z: 2,
    )
  end

  def render
    return if @dead

    @circle.x = @position[0]
    @circle.y = @position[1]

    v = vector_from_magnitude_and_direction(RADIUS, @direction)
    @line.x1 = @position[0]
    @line.y1 = @position[1]
    @line.x2 = @position[0] + v[0]
    @line.y2 = @position[1] + v[1]
  end

protected

  def remote_build(remote_build_order)
    # FIXME: Restrict to only construct structures, and restrict build range
    produce(remote_build_order.unit_class, position: remote_build_order.build_position)
    return build_order
  end
end
