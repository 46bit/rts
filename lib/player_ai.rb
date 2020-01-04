require 'matrix'
require_relative './turret'

def update_turret(turret, player, other_players)
  enemy_vehicles = other_players.map(&:vehicles).flatten
  projectile = turret.update(enemy_vehicles)
  player.add_projectile(projectile) unless projectile.nil?
end

# AI that focuses on seizing the generator closest to each unit. When it has seized all generators
# its units guard their nearest generators.
class GuardNearestAI
  def update(generators, player, other_players)
    targets = generators.reject { |g| g.owner?(player) }
    targets = generators if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead
      if vehicle.class == Turret && vehicle.deployed
        update_turret(vehicle, player, other_players)
        next
      end

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
    targets += other_players.map(&:vehicles).flatten.select { |v| v.class == Turret } if targets.length >= generators.length / 2
    targets += other_players.select { |p| p.vehicles.length <= player.vehicles.length / 4 }.map(&:factories).flatten
    targets = other_players.map(&:factories).flatten + other_players.map(&:vehicles).flatten if targets.empty?
    targets = generators + player.factories if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead
      if vehicle.class == Turret && vehicle.deployed
        update_turret(vehicle, player, other_players)
        next
      end

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
  def initialize(world_size, scale_factor)
    @world_size = world_size
    @scale_factor = scale_factor
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

  def already_building?(player)
    player.factories.select { |f| f.position == @target }[0]
  end

  def building_complete?(player)
    already_building?(player).factory_ready
  end

  def update(generators, player, other_players)
    player.vehicles.each do |vehicle|
      next if vehicle.dead
      if vehicle.class == Turret && vehicle.deployed
        update_turret(vehicle, player, other_players)
        next
      end

      choose_new_target(generators, player, other_players) if @target.nil?
      if @target.nil?
        if @stalled_time > 35
          super
        else
          vehicle.update(accelerate_mode: "forward_and_left")
        end
      elsif (vehicle.position - @target).magnitude < 10
        if reasonable_target?(@target, generators, player, other_players) && !already_building?(player)
          if vehicle.class == Turret
            # FIXME: When deploying a turret the other vehicles follow along. Assign a target to each
            # turret and then move on?
            vehicle.deploy
          else
            vehicle.kill
            player.add_factory Factory.new(
              @target.clone,
              player,
              scale_factor: @scale_factor,
              factory_ready: false,
              health: 20,
            )
          end
        end
        @target = nil if vehicle.class == Turret || building_complete?(player)
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
  def initialize(generators, scale_factor)
    @scale_factor = scale_factor
    average_generator_x = generators.map(&:position).map { |p| p[0] }.sum.to_f / generators.length
    average_generator_y = generators.map(&:position).map { |p| p[1] }.sum.to_f / generators.length
    @target = Vector[average_generator_x, average_generator_y]
  end

  def update(generators, player, other_players)
    return super unless @target && generators.select { |g| g.owner?(player) }.length > 0

    player.vehicles.each do |vehicle|
      next if vehicle.dead
      if vehicle.class == Turret && vehicle.deployed
        update_turret(vehicle, player, other_players)
        next
      end

      if (vehicle.position - @target).magnitude < 10
        unless player.factories.length == 2
          vehicle.kill
          player.add_factory Factory.new(
            @target.clone,
            player,
            scale_factor: @scale_factor,
            factory_ready: false,
            health: 20,
          )
        end
        @target = false if player.factories.length == 2 && player.factories[1].factory_ready
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

class KillFactoriesAI
  def update(generators, player, other_players)
    top_player = other_players.max_by(&:score)
    targets = top_player.factories if top_player
    targets = generators + player.factories if targets.empty?
    player.vehicles.each do |vehicle|
      next if vehicle.dead
      if vehicle.class == Turret && vehicle.deployed
        update_turret(vehicle, player, other_players)
        next
      end

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

class SpamTurretsAI < GuardNearestAI
  def initialize(world_size)
    @world_size = world_size
    @targets = {}
  end

  def choose_new_target(turret, generators, player, other_players)
    target = Vector[
      (0.02 + 0.98 * rand) * @world_size,
      (0.02 + 0.98 * rand) * @world_size,
    ]
    player_generators = generators.select { |g| g.owner?(player) }
    nearest_structure = (player.factories + player_generators).min_by { |f| (target - f.position).magnitude }
    return if (target - nearest_structure.position).magnitude > @world_size / 3
    target if reasonable_target?(target, generators, player, other_players)
  end

  def reasonable_target?(target, generators, player, other_players)
    all_factories = player.factories + other_players.map(&:factories).flatten
    all_turrets = (player.vehicles + other_players.map(&:vehicles).flatten).select { |v| v.class == Turret }
    all_structures = generators + all_factories + all_turrets

    reasonable = true
    all_structures.each do |structure|
      if (structure.position - target).magnitude < 20
        reasonable = false
        break
      end
    end
    return reasonable
  end

  def update(generators, player, other_players)
    super if generators.select { |g| g.owner?(player) }.length < [2, player.vehicles.length / 7].max

    player.vehicles.each do |vehicle|
      next if vehicle.dead
      raise "doesn't support non-turret units" if vehicle.class != Turret

      if vehicle.class == Turret && vehicle.deployed
        update_turret(vehicle, player, other_players)
        next
      end

      target = @targets[vehicle.object_id]
      if target.nil?
        target = choose_new_target(vehicle, generators, player, other_players)
        @targets[vehicle.object_id] = target
      end

      if !target.nil? && (vehicle.position - target).magnitude < 10
        vehicle.deploy
        @targets.delete(vehicle.object_id)
      elsif !target.nil? && vehicle.turn_left_to_reach?(target) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_left")
      elsif !target.nil? && vehicle.turn_right_to_reach?(target) && rand > 0.2
        vehicle.update(accelerate_mode: "forward_and_right")
      else
        vehicle.update(accelerate_mode: "forward")
      end
    end
  end
end
