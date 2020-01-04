require 'matrix'
require_relative './generator'
require_relative './factory'
require_relative './player'
require_relative './player_ai'

class Game
  def self.from_config(config, screen_size: 800)
    world_size = config["size"]
    scale_factor = screen_size.to_f / world_size

    generators = config["generators"].map do |g|
      Generator.new(
        Vector[g["x"], g["y"]],
        capacity: g["capacity"],
        scale_factor: scale_factor,
      )
    end

    players = config["players"].map do |p|
      control = case p["control"]
      when "guard_nearest_ai"
        GuardNearestAI.new
      when "attack_nearest_ai"
        AttackNearestAI.new
      when "spam_factories_ai"
        SpamFactoriesAI.new(world_size, scale_factor)
      when "build_factory_at_centre_then_attack_ai"
        BuildFactoryAtCentreThenAttackAI.new(generators, scale_factor)
      when "kill_factories_ai"
        KillFactoriesAI.new
      else
        raise "no control specified for player with color #{p["color"]}"
      end
      player = Player.new(
        p["color"],
        control,
        unit_cap: config["unit_cap"],
      )
      player.add_factory Factory.new(
        Vector[p["x"], p["y"]],
        player,
        scale_factor: scale_factor,
      )
      player
    end

    return Game.new(
      world_size,
      screen_size,
      generators,
      players,
      sandbox: config.fetch("sandbox", false),
      scale_factor: scale_factor,
    )
  end

  attr_reader :screen_size, :generators, :players, :sandbox, :winner

  def initialize(world_size, screen_size, generators, players, sandbox: false, scale_factor: 1.0)
    @world_size = world_size
    @screen_size = screen_size
    @generators = generators
    @players = players
    @sandbox = sandbox
    @scale_factor = scale_factor
    @winner = false
  end

  def tick
    kill_enemy_things_that_projectiles_collide_with
    remove_killed_projectiles
    capture_generators_and_kill_capturing_vehicles
    remove_killed_vehicles
    kill_colliding_vehicles_and_damage_collided_factories
    kill_arriving_vehicles_and_heal_factories
    remove_killed_vehicles
    remove_killed_factories

    @generators.each(&:render) unless HEADLESS
    @players.each do |player|
      # FIXME: Reallow control over creating new units?
      player.factories.each(&:construct_new)
      player.update(@generators, @players - [player])
      player.render unless HEADLESS
    end
    remove_killed_vehicles
    remove_killed_projectiles

    # puts @players.map { |p| [p.color, p.score] }.inspect
    check_for_winner unless @sandbox || @winner
    if @winner
      if @label
        exit 0 if Time.now - @win_time > 5
      else
        @win_time = Time.now
        puts "#{@winner} wins!"
        exit 0 if HEADLESS
        @label = Text.new(
          "#{@winner} wins!",
          x: @world_size / 2 * @scale_factor,
          y: @world_size / 2 * @scale_factor,
          size: 100 * @scale_factor,
          color: 'white',
          z: 10,
        )
        @label.x -= @label.width / 2
        @label.y -= @label.height / 2
      end
    end
  end

protected

  def check_for_winner
    return if @winner
    players_with_factories = @players.reject { |p| p.factories.empty? }
    players_with_vehicles = @players.reject { |p| p.vehicles.empty? }
    # FIXME: Accommodate players with projectiles
    zeros_match = players_with_factories[0] == players_with_vehicles[0]
    @winner = case [players_with_factories.length, players_with_vehicles.length]
    when [1, 0] # Sole living player only has factories
      players_with_factories[0].color
    when [0, 1] # Sole living player only has vehicles
      players_with_vehicles[0].color
    when [1, 1]
      if players_with_factories[0] == players_with_vehicles[0]
        players_with_vehicles[0].color # Sole living player has factories and vehicles
      else
        false # One player has no factories but still has vehicles so could still win
      end
    when [0, 0]
      "nobody"
    else
      false
    end
  end

  def remove_killed_vehicles
    @players.each do |player|
      player.vehicles.reject! { |v| v.dead }
    end
  end

  def remove_killed_factories
    @players.each do |player|
      player.factories.reject! { |f| f.dead? }
    end
  end

  def remove_killed_projectiles
    @players.each do |player|
      player.projectiles.reject! { |f| f.dead }
    end
  end

  def kill_enemy_things_that_projectiles_collide_with
    @players.product(@players).each do |player_1, player_2|
      next if player_1 == player_2

      player_1.projectiles.each do |projectile|
        # Projectiles can damage multiple things if they collide with them at the same time
        kill_projectile = false
        player_2.vehicles.each do |vehicle|
          if vehicle.collided_with_projectile?(projectile)
            kill_projectile = true
            vehicle.kill
          end
        end
        player_2.factories.each do |factory|
          if factory.collided_with_projectile?(projectile)
            kill_projectile = true
            factory.damage :projectile_collision
          end
        end

        projectile.kill if kill_projectile
      end
    end
  end

  def kill_colliding_vehicles_and_damage_collided_factories
    @players.product(@players).each do |player_1, player_2|
      next if player_1 == player_2
      player_1.vehicles.product(player_2.vehicles).each do |vehicle_1, vehicle_2|
        vehicle_1.kill if vehicle_1.collided_with_vehicle?(vehicle_2)
      end
      player_1.vehicles.product(player_2.factories).each do |vehicle, factory|
        if factory.vehicle_collided?(vehicle)
          vehicle.kill
          factory.damage :vehicle_collision
        end
      end
    end
  end

  def kill_arriving_vehicles_and_heal_factories
    @players.each do |player|
      player.vehicles.product(player.factories).each do |vehicle, factory|
        # FIXME: Give players control over healing active factories
        if !vehicle.dead && factory.damaged? && !factory.factory_ready && factory.vehicle_collided?(vehicle)
          vehicle.kill
          factory.heal
        end
      end
    end
  end

  def capture_generators_and_kill_capturing_vehicles
    @generators.each do |generator|
      @players.each do |player|
        next if generator.owner?(player)
        player.vehicles.each do |vehicle|
          # FIXME: Create a `Generator.captured_by?` method
          if generator.vehicle_collided?(vehicle)
            generator.capture(player)
            vehicle.kill
          end
        end
      end
    end
  end
end
