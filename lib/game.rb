require 'matrix'
require_relative './units/generator'
require_relative './units/factory'
require_relative './renderer/renderer'
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
    damage_enemy_things_that_projectiles_collide_with
    remove_killed_projectiles
    capture_generators_and_kill_capturing_vehicles
    remove_killed_vehicles
    damage_colliding_vehicles_and_structures
    remove_killed_vehicles
    remove_killed_factories

    @players.each do |player|
      player.update(@generators, @players - [player])
    end
    remove_killed_vehicles
    remove_killed_projectiles

    @generators.each do |generator|
      generator.player = nil if generator.player && generator.player.defeated?
    end

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

    undefeated_players = @players.reject { |p| p.defeated? }
    if undefeated_players.empty?
      @winner = "nobody"
    elsif undefeated_players.length == 1
      @winner = undefeated_players[0].color
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

  def damage_enemy_things_that_projectiles_collide_with
    @players.product(@players).each do |player_1, player_2|
      next if player_1 == player_2

      player_1.projectiles.each do |projectile|
        # Projectiles can damage multiple things if they collide with them at the same time
        kill_projectile = false
        player_2.vehicles.each do |vehicle|
          if vehicle.collided?(projectile)
            kill_projectile = true
            vehicle.damage(projectile.damage)
          end
        end
        player_2.factories.each do |factory|
          if factory.collided?(projectile)
            kill_projectile = true
            factory.damage(projectile.damage)
          end
        end
        player_2.turrets.each do |turret|
          if turret.collided?(projectile)
            kill_projectile = true
            turret.damage(projectile.damage)
          end
        end

        projectile.kill if kill_projectile
      end
    end
  end

  def damage_colliding_vehicles_and_structures
    orig_unit_health = Hash[@players.map(&:units).flatten.map { |v| [v.object_id, v.health] }]

    @players.each do |player_1|
      @players.each do |player_2|
        next if player_1 == player_2
        player_1.units.each do |unit_1|
          hit_things = []
          player_2.units.each do |unit_2|
            hit_things << unit_2 if unit_2.alive? && unit_1.collided?(unit_2)
          end
          next if hit_things.empty?
          damage_per_unit = orig_unit_health[unit_1.object_id] / hit_things.length
          hit_things.each { |u| u.damage(damage_per_unit) }
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
            vehicle.damage(10)
          end
        end
      end
    end
  end
end
