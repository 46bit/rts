require 'matrix'
require_relative './units/factory'
require_relative './units/turret'

def ai_from_string(name, world_size, generators)
  case name
  when "guard_nearest_ai"
    GuardNearestAI.new
  when "attack_nearest_ai"
    AttackNearestAI.new
  when "defensive_ai"
    DefensiveAI.new(world_size)
  when "build_factory_at_centre_then_attack_ai"
    BuildFactoryAtCentreThenAttackAI.new(generators)
  when "kill_factories_ai"
    KillFactoriesAI.new
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units guard their nearest generators.
class GuardNearestAI
  def update(generators, player, other_players)
    targets = generators.reject { |g| g.owner?(player) }
    targets = generators if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
      if target.nil?
        vehicle.update(:stop)
      elsif vehicle.turn_left_to_reach?(target.position) && rand > 0.2
        vehicle.update(:turn_left)
      elsif vehicle.turn_right_to_reach?(target.position) && rand > 0.2
        vehicle.update(:turn_right)
      else
        vehicle.update(:forward)
      end
    end
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class AttackNearestAI
  def update(generators, player, other_players)
    targets = generators.reject { |g| g.owner?(player) }
    targets += other_players.map(&:turrets).flatten if targets.length >= generators.length / 2
    targets += other_players.select { |p| p.vehicles.length <= player.vehicles.length / 4 }.map(&:factories).flatten
    targets = other_players.map(&:factories).flatten + other_players.map(&:vehicles).flatten + other_players.map(&:turrets).flatten if targets.empty?
    targets = generators + player.factories if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
      randomness = target.class == Turret ? 0.7 : 0.2
      if target.nil?
        vehicle.update(:stop)
      elsif vehicle.turn_left_to_reach?(target.position) && rand > randomness || rand < 0.1
        vehicle.update(:turn_left)
      elsif vehicle.turn_right_to_reach?(target.position) && rand > randomness || rand < 0.1
        vehicle.update(:turn_right)
      else
        vehicle.update(:forward)
      end
    end
  end
end

class DefensiveAI < AttackNearestAI
  def initialize(world_size, proportion_of_turret_constructions: 0.5)
    @world_size = world_size
    @proportion_of_turret_constructions = proportion_of_turret_constructions
    @targets = {}
    @constructions = []
  end

  def target(vehicle, generators, player, other_players)
    return @targets[vehicle.object_id] if @targets[vehicle.object_id] && (@targets[vehicle.object_id].class == Vector || !@targets[vehicle.object_id].dead)

    nearest_construction = @constructions.reject {|c| c.dead}.min_by { |c| (c.position - vehicle.position).magnitude }
    return nearest_construction if nearest_construction

    enemy_vehicle_positions = other_players.map(&:vehicles).flatten.map(&:position)

    interesting_structures = []
    if player.turrets.length < 10
      interesting_structures += player.factories + player.turrets
    elsif !enemy_vehicle_positions.empty?
      interesting_structures += player.factories.select do |f|
        nearest_enemy_vehicle = enemy_vehicle_positions.min_by { |v| (v - f.position).magnitude }
        (nearest_enemy_vehicle - f.position).magnitude < 45
      end
      interesting_structures += player.turrets.select do |t|
        nearest_enemy_vehicle = enemy_vehicle_positions.min_by { |v| (v - t.position).magnitude }
        (nearest_enemy_vehicle - t.position).magnitude < 45
      end
      combat_focus = true unless interesting_structures.empty?
    end
    interesting_structures += player.factories + player.turrets if interesting_structures.empty?
    interesting_structures += player.vehicles if interesting_structures.empty?

    nearest_structure = interesting_structures.min_by { |s| (s.position - vehicle.position).magnitude }
    range = combat_focus ? 40 : 200
    new_construction = Vector[
      nearest_structure.position[0] + (rand - 0.5) * [0.3 * @world_size, range].min,
      nearest_structure.position[1] + (rand - 0.5) * [0.3 * @world_size, range].min,
    ]

    unless combat_focus
      chosen_enemy = other_players.select { |p| p.unit_count > 0 }.shuffle[0]
      enemy_vehicle_positions = chosen_enemy.vehicles.map(&:position) unless chosen_enemy.nil?
      avg_enemy_vehicle_position = Vector[
        enemy_vehicle_positions.map { |p| p[0] }.sum / [enemy_vehicle_positions.length, 1].max,
        enemy_vehicle_positions.map { |p| p[1] }.sum / [enemy_vehicle_positions.length, 1].max,
      ]
      weigh_enemy_positions = player.turrets.length > 10 ? 0.4 : 0.1
      new_construction = new_construction * (1.0 - weigh_enemy_positions) + avg_enemy_vehicle_position * weigh_enemy_positions
    end

    #new_construction = Vector[
    #  (0.1 + 0.8 * rand) * @world_size,
    #  (0.1 + 0.8 * rand) * @world_size,
    #]
    return new_construction if reasonable_target?(new_construction, generators, player, other_players)
  end

  def reasonable_target?(target, generators, player, other_players)
    all_factories = player.factories + other_players.map(&:factories).flatten
    all_structures = generators + all_factories + other_players.map(&:vehicles).flatten
    reasonable = true
    all_structures.each do |structure|
      if (structure.position - target).magnitude < 30
        reasonable = false
        break
      end
    end
    return reasonable
  end

  def update(generators, player, other_players)
    return super if player.turrets.length == 0 && generators.select { |g| g.owner?(player) }.length < 5 && (other_players.max_by { |p| p.unit_count } == nil || other_players.max_by { |p| p.unit_count }.unit_count < player.unit_count * 2 )
    return super if generators.select { |g| g.owner?(player) }.length < [[player.turrets.select { |t| t.built }.length, 2].min, player.vehicles.length / 5].max

    player.vehicles.each do |vehicle|
      next if vehicle.dead

      vehicle_target = target(vehicle, generators, player, other_players)
      if vehicle_target.nil?
        vehicle.update(:turn_left)
        next
      end
      target_position = vehicle_target.class == Vector ? vehicle_target : vehicle_target.position

      if vehicle_target.class == Vector && (vehicle_target - vehicle.position).magnitude < 10
        #puts "#{player.color}: constructing at #{target_position}"
        structure_type = player.turrets.length == 0 || rand > @proportion_of_turret_constructions || player.factories.length > 1 ? Turret : Factory
        structure = vehicle.construct_structure(structure_type)
        case structure
        when Turret
          player.turrets << structure
        when Factory
          player.factories << structure
        else
          raise "should be unreachable"
        end
        @constructions << structure
      elsif vehicle_target.class != Vector && vehicle_target.collided?(vehicle)
        #puts "#{player.color}: repairing at #{target_position}"
        vehicle.repair_structure(vehicle_target)
        if vehicle_target.built
          #puts "finished"
          @constructions.delete(vehicle_target)
        end
      elsif vehicle.turn_left_to_reach?(target_position) && rand > 0.2
        vehicle.update(:turn_left)
      elsif vehicle.turn_right_to_reach?(target_position) && rand > 0.2
        vehicle.update(:turn_right)
      else
        vehicle.update(:forward)
      end
    end
  end
end

class BuildFactoryAtCentreThenAttackAI < AttackNearestAI
  def initialize(generators)
    average_generator_x = generators.map(&:position).map { |p| p[0] }.sum.to_f / generators.length
    average_generator_y = generators.map(&:position).map { |p| p[1] }.sum.to_f / generators.length
    @target = Vector[average_generator_x, average_generator_y]
  end

  def update(generators, player, other_players)
    return super if !@target || generators.select { |g| g.owner?(player) }.length < 2 || (@target.class != Vector && @target.dead)

    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target_position = @target.class == Vector ? @target : @target.position
      if (vehicle.position - target_position).magnitude < 10
        if @target.class == Vector
          structure = vehicle.construct_structure(Factory)
          player.factories << structure
          @target = structure
        else
          vehicle.repair_structure(@target)
          if @target.built
            #puts "finished"
            @target = nil
          end
        end
        break
      elsif vehicle.turn_left_to_reach?(target_position) && rand > 0.2
        vehicle.update(:turn_left)
      elsif vehicle.turn_right_to_reach?(target_position) && rand > 0.2
        vehicle.update(:turn_right)
      else
        vehicle.update(:forward)
      end
    end
  end
end

class KillFactoriesAI
  def update(generators, player, other_players)
    weakest_player = other_players.min_by(&:unit_count)
    targets = weakest_player.factories if weakest_player
    targets = generators + player.factories + player.turrets if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
      if target.nil?
        vehicle.update(:stop)
      elsif vehicle.turn_left_to_reach?(target.position) && rand > 0.2
        vehicle.update(:turn_left)
      elsif vehicle.turn_right_to_reach?(target.position) && rand > 0.2
        vehicle.update(:turn_right)
      else
        vehicle.update(:forward)
      end
    end
  end
end
