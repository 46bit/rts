ManoeuvreOrder = Struct.new(:destination)
BuildOrder = Struct.new(:unit_class)
RemoteBuildOrder = Struct.new(:build_position, :unit_class)

module Orderable
  attr_reader :order_callbacks, :order

  def initialize_orderable(order_callbacks)
    @order_callbacks = order_callbacks
    @order = nil
  end

  def order(order)
    @order = order
  end

  def update_orders
    callback = @order_callbacks[@order.class]
    raise "unexpected order type: #{@order.inspect}" if callback.nil?
    @order = instance_exec(@order, &callback)
  end
end
