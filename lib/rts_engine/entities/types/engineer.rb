require_relative "./vehicle"
require_relative "../capabilities/engineerable"

DEFAULT_ENGINEER_ORDER_CALLBACKS = DEFAULT_VEHICLE_ORDER_CALLBACKS.merge(
  RemoteBuildOrder => lambda { |o| remote_build(o) },
)

# FIXME: I think this should be an extension of the `Engineer` capability, not a class.
class Engineer < Vehicle
  include Engineerable

  attr_reader :build_beam

  def initialize(*args, production_range: 25.0, order_callbacks: DEFAULT_ENGINEER_ORDER_CALLBACKS, **kargs)
    super(
      *args,
      order_callbacks: order_callbacks,
      **kargs,
    )
    initialize_engineerable(production_range: production_range)
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
        patrol_location PatrolLocationOrder.new(remote_build_order.build_position, @production_range)
      else
        @unit = nil
        manoeuvre ManoeuvreOrder.new(remote_build_order.build_position)
      end
    elsif within_production_range?(remote_build_order.build_position)
      unit_class = remote_build_order.unit_class
      if !unit_class.respond_to?(:buildable_by_mobile_units?) || !unit_class.buildable_by_mobile_units?
        raise "told to construct '#{remote_build_order}' but it is not buildable by module units"
      end

      produce(remote_build_order.unit_class, position: remote_build_order.build_position)
      remote_build_order.unit = @unit
      patrol_location PatrolLocationOrder.new(remote_build_order.build_position, @production_range)
    else
      return nil
    end
    remote_build_order
  end
end