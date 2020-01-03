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
        vehicle.update(accelerate_mode: "")
      elsif vehicle.turn_left_to_reach?(target.position) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_left")
      elsif vehicle.turn_right_to_reach?(target.position) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_right")
      else
        vehicle.update(accelerate_mode: "forward")
      end
    end
  end
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units swarm enemy units and factories.
class AttackNearestAI
  def update(generators, player, other_players)
    targets = generators.reject { |g| g.owner?(player) }
    targets = other_players.map(&:factories).flatten + other_players.map(&:vehicles).flatten if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead

      target = targets.min_by { |t| (t.position - vehicle.position).magnitude }
      if target.nil?
        vehicle.update(accelerate_mode: "")
      elsif vehicle.turn_left_to_reach?(target.position) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_left")
      elsif vehicle.turn_right_to_reach?(target.position) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_right")
      else
        vehicle.update(accelerate_mode: "forward")
      end
    end
  end
end
