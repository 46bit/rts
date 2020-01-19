require "matrix"
require_relative "./entities/capabilities/orderable"
require_relative "./entities/bot"
require_relative "./entities/tank"
require_relative "./entities/generator"
require_relative "./entities/factory"
require_relative "./entities/turret"

def ai_from_string(name, _world_size, _power_sources)
  case name
  when "guard_nearest_ai"
    GuardNearestAI.new
  when "attack_nearest_ai"
    AttackNearestAI.new
  when "build_turrets_ai"
    BuildTurretsAI.new
  else
    raise "unknown ai name specified: '#{name}'"
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units guard their nearest generators.
class GuardNearestAI
  def update(power_sources, player, other_players, direct_fire_quadtree)
    if (player.factories.empty? || player.energy > 500) && !player.vehicles.empty?
      new_factory_location = player.constructions.select { |c| c.is_a?(Factory) }[0]&.position
      new_factory_location ||= player.vehicles.map(&:position).inject(:+) / player.vehicles.length
      player.vehicles.each do |vehicle|
        if vehicle.class.included_modules.include?(Engineerable)
          vehicle.order = RemoteBuildOrder.new(new_factory_location, Factory)
        end
      end
      return
    end

    player.factories.each { |f| f.produce(Bot) }

    targets = power_sources.reject { |g| g.owner?(player) && g.structure.built? }
    targets += other_players.select { |p| p.units.length <= player.vehicles.length / 4 }.map(&:units).flatten
    targets = power_sources if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      vehicle_targets = targets.clone
      if !vehicle.respond_to?(:producing?)
        vehicle_targets.reject! { |t| t.class == PowerSource || t.owned?(self) }
      end
      target = vehicle_targets.min_by { |t| (t.position - vehicle.position).magnitude }
      vehicle.order = if target.nil?
                        nil
                      elsif target.class == PowerSource
                        if target.occupied? && !target.owner?(player)
                          AttackOrder.new(target)
                        elsif target.occupied? && !target.structure.built?
                          RemoteBuildOrder.new(target, Generator)
                        else
                          ManoeuvreOrder.new(target.position)
                        end
                      else
                        ManoeuvreOrder.new(target.position)
                      end
    end

    # max_vehicles_of_any_player = other_players.map { |p| p.vehicles.length }.max
    generators_upgrading = player.generators.select { |g| g.upgrading? }
    #if player.vehicles.length >= 0.8 ** max_vehicles_of_any_player && generators_upgrading.empty?
    if generators_upgrading.empty?
      random_generator = player.generators.shuffle[0]&.upgrade
    end
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class AttackNearestAI
  def update(power_sources, player, other_players, direct_fire_quadtree)
    if (player.factories.empty? || player.energy > 500) && !player.vehicles.empty?
      player.factories.each { |f| f.produce(Bot) }
      new_factory_location = player.constructions.select { |c| c.is_a?(Factory) }[0]&.position
      new_factory_location ||= player.vehicles.map(&:position).inject(:+) / player.vehicles.length
      player.vehicles.each do |vehicle|
        if vehicle.class.included_modules.include?(Engineerable)
          vehicle.order = RemoteBuildOrder.new(new_factory_location, Factory)
        end
      end
      return
    end

    targets = power_sources.reject { |g| g.owner?(player) && g.structure.built? }
    targets += other_players.map(&:turrets).flatten #if targets.length < power_sources.length / 2
    targets += other_players.select { |p| p.vehicles.length <= player.vehicles.length / 3 }.map(&:units).flatten
    targets = other_players.map(&:factories).flatten + other_players.map(&:vehicles).flatten + other_players.map(&:turrets).flatten if targets.empty?
    targets = power_sources + player.factories if targets.empty?
    targets += other_players.map(&:units).flatten

    living_other_players = other_players.select { |p| p.unit_count.positive? }
    if living_other_players.length == 1 && living_other_players[0].turrets.length > 1 && rand > 0.25
      player.factories.each { |f| f.produce(Tank) }
    else
      player.factories.each { |f| f.produce(Bot) }
    end

    targets_near_turret = targets.select do |target|
      !direct_fire_quadtree.collision_for(target, player: player, within: TurretProjectile::RANGE).empty?
    end
    #puts "#{player.color}: #{targets_near_turret.group_by(&:class).transform_values(&:length).inspect} targets near turret"
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      vehicle_targets = targets.clone
      if !vehicle.respond_to?(:producing?)
        vehicle_targets.reject! { |t| t.class == PowerSource || t.owner?(self) }
      end
      target = vehicle_targets.min_by do |t|
        distance = (t.position - vehicle.position).magnitude
        #distance_to_nearest_enemy_turret = other_players.map(&:turrets).flatten.map { |t2| (t2.position - t.position).magnitude }.min || 0
        #distance *= 20 if distance_to_nearest_enemy_turret > 0 && distance_to_nearest_enemy_turret <= TurretProjectile::RANGE
        distance *= 20 if targets_near_turret.include?(t) # !direct_fire_quadtree.collision_for(t, player: player).empty?
        distance #+ distance_to_nearest_enemy_turret * 5 + (t.class == Turret ? distance * 3 : 0)
      end
      vehicle.order = if target.nil?
                        nil
                      elsif target.class == PowerSource
                        if target.occupied? && !target.owner?(player)
                          AttackOrder.new(target)
                        else
                          RemoteBuildOrder.new(target, Generator)
                        end
                      else
                        ManoeuvreOrder.new(target.position)
                      end
    end

    if !player.factories.empty? && player.generators.select { |g| g.upgrading? }.empty?
      enemies = other_players.map(&:units).flatten
      generator_upgrade_priority = player.generators.min_by do |g|
        distance_to_nearest_enemy = enemies.map { |e| (e.position - g.position).magnitude }.min
        # distance_to_nearest_factory = player.factories.map { |f| (f.position - g.position).magnitude }.min
        g.capacity.to_f / distance_to_nearest_enemy
      end
      generator_upgrade_priority&.upgrade
    end
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class BuildTurretsAI
  def update(_power_sources, player, _other_players, direct_fire_quadtree)
    if player.factories.empty? && !player.vehicles.empty?
      new_factory_location = player.constructions.select { |c| c.is_a?(Factory) }[0]&.position
      new_factory_location ||= player.vehicles.map(&:position).inject(:+) / player.vehicles.length
      player.vehicles.each do |vehicle|
        vehicle.order = RemoteBuildOrder.new(new_factory_location, Factory)
      end
      return
    end

    player.factories.each { |f| f.produce(Bot) }

    base = player.factories[0] || player.turrets[0] || player.commander || player.units[0] || return
    build_at = Vector[
      base.position[0] + (1 + player.turrets.length) * 30,
      base.position[1],
    ]
    already_building = player.vehicles.reject { |v| v.order == nil }[0]

    player.vehicles.each do |vehicle|
      next if vehicle.dead

      vehicle.order = if already_building
                        already_building.order
                      else
                        RemoteBuildOrder.new(build_at, Turret)
                      end
    end
  end
end
