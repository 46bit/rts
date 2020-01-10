require_relative './entity'
require_relative './capabilities/ownable'
require_relative './capabilities/orderable'
require_relative './capabilities/buildable'
require_relative './capabilities/collidable'
require_relative './capabilities/manoeuvrable'

DEFAULT_VEHICLE_ORDER_CALLBACKS = {
  NilClass => lambda {
    apply_drag_forces
    return nil
  },
  ManoeuvreOrder => lambda { |o| manoeuvre(o) },
}

class Vehicle < Entity
  include Ownable
  include Orderable
  include Buildable
  include Collidable
  include Manoeuvrable

  attr_reader :order

  def initialize(renderer, position, player, max_health:, health: nil, built: false, cost: max_health * 10, direction: rand * Math::PI * 2, physics: DEFAULT_PHYSICS, turn_rate: 1.0, movement_rate: 1.0, collision_radius:, order_callbacks: DEFAULT_VEHICLE_ORDER_CALLBACKS)
    super(renderer, position)
    initialize_ownable(player: player)
    initialize_buildable(max_health: max_health, health: health, built: built, cost: cost)
    initialize_collidable(collision_radius: collision_radius)
    initialize_manoeuvrable(physics: physics, velocity: 0.0, direction: direction, angular_velocity: 0.0)
    initialize_orderable(order_callbacks)
    @movement_rate = movement_rate
    @turn_rate = turn_rate
  end

  def order(order)
    @order = order
  end

  def update
    return if @dead

    update_orders
    update_direction(multiplier: @turn_rate)
    update_position(multiplier: @movement_rate)
  end

protected

  def manoeuvre(manoeuvre_order)
    if (@position - manoeuvre_order.destination).magnitude < 10
      # apply_drag_forces
      # return nil
      # FIXME: Decide what to do when at destination. Turn in a circle (below) or stop (above)?
      update_velocities(turning_angle: @physics.turning_angle)
    elsif self.turn_left_to_reach?(manoeuvre_order.destination) && rand > 0.2
      update_velocities(turning_angle: @physics.turning_angle)
    elsif self.turn_right_to_reach?(manoeuvre_order.destination) && rand > 0.2
      update_velocities(turning_angle: -@physics.turning_angle)
    else
      update_velocities(turning_angle: 0.0)
    end
    return manoeuvre_order
  end
end
