require_relative '../entities/vehicle'
require_relative './capabilities/engineerable'

DEFAULT_ENGINEER_ORDER_CALLBACKS = DEFAULT_VEHICLE_ORDER_CALLBACKS.merge({
  RemoteBuildOrder => lambda { |o| remote_build(o) },
})

# FIXME: I think this should be an extension of the `Engineer` capability, not a class.
class Engineer < Vehicle
  include Engineerable

  attr_reader :build_beam

  def initialize(*args, production_range: 25.0, prerender_constructions: true, order_callbacks: DEFAULT_ENGINEER_ORDER_CALLBACKS, **kargs)
    super(
      *args,
      order_callbacks: order_callbacks,
      **kargs,
    )
    initialize_engineerable(production_range: production_range, prerender_constructions: prerender_constructions)
  end

  def kill
    super
    # FIXME: This makes sense for Factories but it overstretches the meaning of prerender_constructions
    @unit.kill unless @prerender_constructions
    @build_beam.remove if !HEADLESS && @build_beam
  end

  def prerender
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

    if @unit.nil? || !@prerender_constructions
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
    update_production
  end

protected

  def remote_build(remote_build_order)
    return nil if remote_build_order.unit && (remote_build_order.unit.built? || remote_build_order.unit.dead?)
    if producing? && @unit.position == remote_build_order.build_position && @unit.is_a?(remote_build_order.unit_class)
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
