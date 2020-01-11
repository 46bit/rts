require 'matrix'
require_relative './entities/capabilities/orderable'
require_relative './units/bot'
require_relative './units/tank'
require_relative './units/factory'
require_relative './units/turret'

def ai_from_string(name, world_size, generators)
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
  def update(generators, player, other_players)
    player.factories.each { |f| f.produce(Bot) }

    targets = generators.reject { |g| g.owner?(player) }
    targets = generators if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
      if target.nil?
        vehicle.order = nil
      else
        vehicle.order = ManoeuvreOrder.new(target.position)
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

    living_other_players = other_players.select { |p| p.unit_count > 0 }
    if living_other_players.length == 1 && living_other_players[0].turrets.length > 1
      player.factories.each { |f| f.produce(Tank) }
    else
      player.factories.each { |f| f.produce(Bot) }
    end

    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
      if target.nil?
        vehicle.order = nil
      else
        vehicle.order = ManoeuvreOrder.new(target.position)
      end
    end
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class BuildTurretsAI
  def update(generators, player, other_players)
    return if player.factories.empty?

    player.factories.each { |f| f.produce(Bot) }

    build_at = Vector[
      player.factories[0].position[0] + (1 + player.turrets.length) * 30,
      player.factories[0].position[1],
    ]
    already_building = player.vehicles.select { |v| v.order != nil }[0]

    player.vehicles.each do |vehicle|
      next if vehicle.dead

      if already_building
        vehicle.order = already_building.order
      else
        vehicle.order = RemoteBuildOrder.new(build_at, Turret)
      end
    end
  end
end
