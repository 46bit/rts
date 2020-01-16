require_relative "./entity"
require_relative "../capabilities/ownable"
require_relative "../capabilities/orderable"
require_relative "../capabilities/buildable"
require_relative "../capabilities/collidable"
require_relative "../capabilities/manoeuvrable"

DEFAULT_VEHICLE_ORDER_CALLBACKS = {
  NilClass => lambda do |_o|
    apply_drag_forces
    return nil
  end,
  ManoeuvreOrder => lambda { |o| manoeuvre(o) },
  AttackOrder => lambda { |o| attack(o) },
  PatrolLocationOrder => lambda { |o| patrol_location(o) },
  GuardOrder => lambda { |o| guard(o) },
}.freeze

class Vehicle < Entity
  include Ownable
  include Orderable
  include Buildable
  include Collidable
  include Manoeuvrable

  attr_reader :order, :movement_rate, :turn_rate

  def initialize(renderer, position, player, max_health:, health: nil, built: false, cost: max_health * 10, direction: rand * Math::PI * 2, physics: DEFAULT_PHYSICS, turn_rate: 1.0, movement_rate: 1.0, collision_radius:, order_callbacks: DEFAULT_VEHICLE_ORDER_CALLBACKS)
    super(renderer, position)
    initialize_ownable(player: player)
    initialize_orderable(order_callbacks)
    initialize_buildable(max_health: max_health, health: health, built: built, cost: cost)
    initialize_collidable(collision_radius: collision_radius)
    initialize_manoeuvrable(physics: physics, velocity: 0.0, direction: direction, angular_velocity: 0.0)
    @movement_rate = movement_rate
    @turn_rate = turn_rate
  end

  def update
    return if @dead

    update_orders
    update_direction(multiplier: @turn_rate)
    update_position(multiplier: @movement_rate)
  end

protected

  def manoeuvre(manoeuvre_order, force_multiplier: 1.0)
    if (@position - manoeuvre_order.destination).magnitude < 10
      # apply_drag_forces
      # return nil
      # FIXME: Decide what to do when at destination. Turn in a circle (below) or stop (above)?
      update_velocities(turning_angle: @physics.turning_angle, force_multiplier: force_multiplier)
    elsif self.turn_left_to_reach?(manoeuvre_order.destination) && rand > 0.2
      update_velocities(turning_angle: @physics.turning_angle, force_multiplier: force_multiplier)
    elsif self.turn_right_to_reach?(manoeuvre_order.destination) && rand > 0.2
      update_velocities(turning_angle: -@physics.turning_angle, force_multiplier: force_multiplier)
    else
      update_velocities(turning_angle: 0.0, force_multiplier: force_multiplier)
    end
    manoeuvre_order
  end

  def attack(attack_order)
    target_unit = attack_order.target_unit
    return nil if target_unit && target_unit.respond_to?(:dead?) && target_unit.dead?

    manoeuvre(ManoeuvreOrder.new(target_unit.position))
    attack_order
  end

  def patrol_location(patrol_location_order)
    if (patrol_location_order.position - @position).magnitude <= patrol_location_order.range
      manoeuvre ManoeuvreOrder.new(patrol_location_order.position), force_multiplier: 0.4
    else
      manoeuvre(ManoeuvreOrder.new(patrol_location_order.position))
    end
  end

  def guard(guard_order)
    if guard_order.unit.is_a?(Vector)
      guarding_position = guard_order.unit
    else
      if guard_order.unit.player != @player
        attack AttackOrder.new(guard_order.unit)
        return guard_order
      end
      guarding_position = guard_order.unit.position
    end

    nearest_enemy_unit = @player.enemy_units.min_by { |u| (u.position - @position).magnitude }
    if nearest_enemy_unit && (nearest_enemy_unit.position - @position).magnitude <= guard_order.attack_range
      attack AttackOrder.new(nearest_enemy_unit)
    else
      patrol_location PatrolLocationOrder.new(guarding_position, guard_order.range)
    end
    guard_order
  end
end
