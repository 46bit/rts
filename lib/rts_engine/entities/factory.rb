require_relative "./types/structure"
require_relative "./capabilities/orderable"
require_relative "./capabilities/engineerable"

FACTORY_ORDER_CALLBACKS = {
  NilClass => lambda { |_o| nil },
  BuildOrder => lambda { |o| build(o) },
}.freeze

class Factory < Structure
  include Orderable
  include Engineerable

  def initialize(renderer, position, player, built: true)
    super(renderer, position, player, max_health: 120, built: built, health: built ? 120 : 0, collision_radius: 15)
    initialize_engineerable
    initialize_orderable(FACTORY_ORDER_CALLBACKS)
  end

  def produce(unit_class, cancel_in_progress: false, **kargs)
    if @unit
      return unless cancel_in_progress

      @unit.kill
      @unit = nil
    end

    start_constructing(unit_class, @position, **kargs) if built?
  end

  def kill
    super
    @unit&.kill
  end

  def update
    update_production unless dead?
  end

protected

  def build(build_order)
    produce(build_order.unit_class)
    build_order
  end
end
