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
  def update(power_sources, player, _other_players)
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
    targets = power_sources if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
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
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class AttackNearestAI
  def update(power_sources, player, other_players)
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
    targets += other_players.map(&:turrets).flatten if targets.length >= power_sources.length / 2
    targets += other_players.select { |p| p.vehicles.length <= player.vehicles.length / 4 }.map(&:factories).flatten
    targets = other_players.map(&:factories).flatten + other_players.map(&:vehicles).flatten + other_players.map(&:turrets).flatten if targets.empty?
    targets = power_sources + player.factories if targets.empty?

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
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class BuildTurretsAI
  def update(_power_sources, player, _other_players)
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
