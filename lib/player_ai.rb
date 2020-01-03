require 'matrix'

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
    targets = generators + player.factories if targets.empty?
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

class SpamFactoriesAI < GuardNearestAI
  def initialize(world_size)
    @world_size = world_size
    @stalled_time = 0
  end

  def choose_new_target(generators, player, other_players)
    @target = nil
    target = Vector[
      (0.1 + 0.8 * rand) * @world_size,
      (0.1 + 0.8 * rand) * @world_size,
    ]
    if reasonable_target?(target, generators, player, other_players)
      stalled_time = 0
      @target = target
    end
    @stalled_time += 1
  end

  def reasonable_target?(target, generators, player, other_players)
    all_factories = player.factories + other_players.map(&:factories).flatten
    all_structures = generators + all_factories
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
    player.vehicles.each do |vehicle|
      choose_new_target(generators, player, other_players) if @target.nil?
      if @target.nil?
        if @stalled_time > 35
          super
        else
          vehicle.update(accelerate_mode: "forward_and_left")
        end
      elsif (vehicle.position - @target).magnitude < 10
        if reasonable_target?(@target, generators, player, other_players)
          vehicle.kill
          player.add_factory Factory.new(
            @target.clone,
            player,
            build_time: player.factories[0].build_time,
            scale_factor: player.factories[0].scale_factor,
          )
        end
        @target = nil
      elsif vehicle.turn_left_to_reach?(@target) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_left")
      elsif vehicle.turn_right_to_reach?(@target) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_right")
      else
        vehicle.update(accelerate_mode: "forward")
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
    return super unless @target

    player.vehicles.each do |vehicle|
      if (vehicle.position - @target).magnitude < 10
        vehicle.kill
        player.add_factory Factory.new(
          @target.clone,
          player,
          build_time: player.factories[0].build_time,
          scale_factor: player.factories[0].scale_factor,
        )
        @target = false
        break
      elsif vehicle.turn_left_to_reach?(@target) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_left")
      elsif vehicle.turn_right_to_reach?(@target) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_right")
      else
        vehicle.update(accelerate_mode: "forward")
      end
    end
  end
end
