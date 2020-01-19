ManoeuvreOrder = Struct.new(:destination)
class StopOrder; end
BuildOrder = Struct.new(:unit_class)
RemoteBuildOrder = Struct.new(:build_at, :unit_class) do
  def build_position
    build_at.class == Vector ? build_at : build_at.position
  end
end
ConstructOrder = Struct.new(:unit)
AttackOrder = Struct.new(:target_unit)
PatrolLocationOrder = Struct.new(:position, :range)
GuardOrder = Struct.new(:unit, :range, :attack_range)

module Orderable
  attr_reader :order_callbacks, :order

  def initialize_orderable(order_callbacks)
    @order_callbacks = order_callbacks
    @order = nil
  end

  def order=(order)
    @order = order
  end

  def update_orders
    callback = @order_callbacks[@order.class]
    raise "unexpected order type for #{self}: #{@order.inspect}" if callback.nil?

    @order = instance_exec(@order, &callback)
  end
end
