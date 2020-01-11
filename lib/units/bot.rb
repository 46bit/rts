require_relative '../entities/vehicle'

class Bot < Vehicle
  include Engineerable

  RADIUS = 5.0
  SACRIFICIAL_REPAIR_VALUE = 20

  attr_reader :circle, :line, :build_beam

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
    initialize_engineerable(production_range: 25.0, prerender_constructions: true)
    prerender unless HEADLESS || !built
  end

  def kill
    super
    return if HEADLESS
    @circle.remove if @circle
    @line.remove if @line
    @build_beam.remove if @build_beam
  end

  def prerender
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
      color: 'black',
      z: 2,
    )
    @build_beam ||= @renderer.line(
      x1: 0,
      y1: 0,
      x2: 0,
      y2: 0,
      width: 1,
      color: @player.color,
      opacity: 0,
      z: 0,
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

    if @unit.nil?
      @build_beam.opacity = 0
    else
      @build_beam.x1 = @position[0]
      @build_beam.y1 = @position[1]
      @build_beam.x2 = @unit.position[0]
      @build_beam.y2 = @unit.position[1]
      @build_beam.opacity = 1
      @unit.render
    end
  end

  def update
    return if dead?
    super
    return update_production
  end

protected

  def remote_build(remote_build_order)
    return nil if remote_build_order.unit && (remote_build_order.unit.built? || remote_build_order.unit.dead?)
    if producing? && @unit.position == remote_build_order.build_position && @unit.class == remote_build_order.unit_class
      if within_production_range?(remote_build_order.build_position)
        manoeuvre ManoeuvreOrder.new(remote_build_order.build_position), force_multiplier: 0.4
      else
        @unit = nil
        manoeuvre(ManoeuvreOrder.new(remote_build_order.build_position))
      end
    else
      if within_production_range?(remote_build_order.build_position)
        unit_class = remote_build_order.unit_class
        if !unit_class.respond_to?(:buildable_by_mobile_units?) || !unit_class.buildable_by_mobile_units?
          raise "told to construct '#{remote_build_order}' but it is not buildable by module units"
        end
        produce(remote_build_order.unit_class, position: remote_build_order.build_position)
        remote_build_order.unit = @unit
      else
        manoeuvre(ManoeuvreOrder.new(remote_build_order.build_position))
      end
    end
    return remote_build_order
  end
end
