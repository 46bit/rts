require_relative "./vehicle"
require_relative "../capabilities/engineerable"

DEFAULT_ENGINEER_ORDER_CALLBACKS = DEFAULT_VEHICLE_ORDER_CALLBACKS.merge(
  RemoteBuildOrder => lambda { |o| remote_build(o) },
  ConstructOrder => lambda { |o| construct(o) },
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
    # FIXME: Stop going to the location if construction started then stopped. The only sensible thing
    # is to record unstarted constructions, I just don't know how to neatly avoid rendering them yet.
    if within_production_range?(remote_build_order.build_position)
      if remote_build_order.build_at.class != Vector
        if remote_build_order.build_at.occupied? && !remote_build_order.build_at.owner?(@player)
          return nil
        end
      end

      # FIXME: These APIs need more thought
      unless start_constructing(remote_build_order.unit_class, remote_build_order.build_at)
        raise "unable to start constructing: #{remote_build_order}"
      end

      stop StopOrder.new
      return ConstructOrder.new(@unit)
    end

    manoeuvre ManoeuvreOrder.new(remote_build_order.build_position)
    remote_build_order
  end

  def construct(construct_order)
    return nil if construct_order.unit.built? || construct_order.unit.dead?

    if construct_order.unit != @unit
      @unit = construct_order.unit
    end

    if within_production_range?(construct_order.unit.position)
      stop StopOrder.new
    else
      manoeuvre ManoeuvreOrder.new(construct_order.unit.position)
    end
    construct_order
  end
end
