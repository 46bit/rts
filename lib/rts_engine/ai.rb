require "matrix"
require_relative "./entities/capabilities/orderable"
require_relative "./entities/bot"
require_relative "./entities/tank"
require_relative "./entities/factory"
require_relative "./entities/turret"

def ai_from_string(name, _world_size, _generators)
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
  def update(generators, player, _other_players)
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

    targets = generators.reject { |g| g.owner?(player) }
    targets = generators if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
      vehicle.order = if target.nil?
                        nil
                      else
                        ManoeuvreOrder.new(target.position)
                      end
    end
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class AttackNearestAI
  def update(generators, player, other_players)
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

    targets = generators.reject { |g| g.owner?(player) }
    targets += other_players.map(&:turrets).flatten if targets.length >= generators.length / 2
    targets += other_players.select { |p| p.vehicles.length <= player.vehicles.length / 4 }.map(&:factories).flatten
    targets = other_players.map(&:factories).flatten + other_players.map(&:vehicles).flatten + other_players.map(&:turrets).flatten if targets.empty?
    targets = generators + player.factories if targets.empty?

    living_other_players = other_players.select { |p| p.unit_count.positive? }
    if living_other_players.length == 1 && living_other_players[0].turrets.length > 1
      player.factories.each { |f| f.produce(Tank) }
    else
      player.factories.each { |f| f.produce(Bot) }
    end

    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
      vehicle.order = if target.nil?
                        nil
                      else
                        ManoeuvreOrder.new(target.position)
                      end
    end
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class BuildTurretsAI
  def update(_generators, player, _other_players)
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
