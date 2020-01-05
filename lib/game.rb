require 'matrix'
require_relative './structures/generator'
require_relative './structures/factory'
require_relative './renderer'
require_relative './player'
require_relative './ai'

class Game
  def self.from_config(config, screen_size: 800)
    renderer = Renderer.new(screen_size, config.fetch("world_size"))

    generators = config.fetch("generators").map do |generator_config|
      Generator::from_config(generator_config, renderer)
    end
    players = config.fetch("players").map do |player_config|
      Player::from_config(player_config, config.fetch("unit_cap"), renderer, generators)
    end
    return Game.new(
      renderer,
      generators,
      players,
      sandbox: config.fetch("sandbox", false),
    )
  end

  attr_reader :renderer, :generators, :players, :sandbox, :winner

  def initialize(renderer, generators, players, sandbox: false)
    @renderer = renderer
    @generators = generators
    @players = players
    @sandbox = sandbox
    @winner = false
  end

  def update
    kill_enemy_things_that_projectiles_collide_with
    remove_killed_projectiles
    capture_generators_and_kill_capturing_vehicles
    remove_killed_vehicles
    kill_colliding_vehicles_and_damage_collided_factories
    remove_killed_vehicles
    remove_killed_factories

    @players.each do |player|
      # FIXME: Reallow control over creating new units?
      player.factories.each(&:construct)
      player.update(@generators, @players - [player])
    end
    remove_killed_vehicles
    remove_killed_projectiles

    dead_players = @players.select { |p| p.unit_count.zero? }
    @generators.select { |p| dead_players.include?(p) }.each { |g| g.player = nil }

    check_for_winner unless @sandbox || @winner
  end

  def render
    @generators.each(&:render)
    @players.each(&:render)

    if @winner
      exit 0 if Time.now - @win_time > 5
      unless @label
        exit 0 if HEADLESS
        @label = @renderer.text(
          "#{@winner} wins!",
          x: @renderer.world_size / 2,
          y: @renderer.world_size / 2,
          size: 100,
          color: 'white',
          z: 10,
        )
        @label.align_centre
        @label.align_middle
      end
    end
  end

protected

  def check_for_winner
    return if @winner

    players_with_a_positive_unit_count = @players.select { |p| p.unit_count > 0 }
    players_with_projectiles = @players.select { |p| p.projectiles.length > 0 }
    active_players = (players_with_a_positive_unit_count + players_with_projectiles).uniq
    if active_players.length == 0
      @winner = "nobody"
    elsif active_players.length == 1
      @winner = active_players[0].color
    end

    if @winner
      puts "#{@winner} wins!"
      @win_time = Time.now
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
          if factory.collided?(projectile)
            kill_projectile = true
            factory.damage(projectile.damage_type)
          end
        end
        player_2.turrets.each do |turret|
          if turret.collided?(projectile)
            kill_projectile = true
            turret.damage(projectile.damage_type)
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
        if factory.collided?(vehicle)
          vehicle.kill
          factory.damage :vehicle_collision
        end
      end
      player_1.vehicles.product(player_2.turrets).each do |vehicle, turret|
        if turret.collided?(vehicle)
          vehicle.kill
          turret.damage :vehicle_collision
        end
      end
    end
  end

  def capture_generators_and_kill_capturing_vehicles
    @generators.each do |generator|
      @players.each do |player|
        next if generator.owner?(player)
        player.vehicles.each do |vehicle|
          if generator.collided?(vehicle)
            generator.capture(player)
            vehicle.kill
          end
        end
      end
    end
  end
end
