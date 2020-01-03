require 'matrix'
require_relative './generator'
require_relative './factory'
require_relative './player'
require_relative './player_ai'

class Game
  def self.from_config(config, screen_size: 800)
    scale_factor = screen_size.to_f / config["size"]
    velocity_scale_factor = 0.075

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
        color: p["color"],
        build_time: config["build_time"],
        scale_factor: scale_factor,
        velocity_scale_factor: velocity_scale_factor,
      )
      player
    end

    return Game.new(screen_size, generators, players)
  end

  attr_reader :screen_size, :generators, :players

  def initialize(screen_size, generators, players)
    @screen_size = screen_size
    @generators = generators
    @players = players
  end

  def tick
    capture_generators_and_kill_capturing_vehicles
    remove_killed_vehicles
    kill_colliding_vehicles
    remove_killed_vehicles

    @generators.each(&:tick)
    @players.each do |player|
      # FIXME: Reallow control over creating new units?
      player.factories.each(&:construct_new)
      player.update(@generators, @players - [player])
      player.render
    end
    remove_killed_vehicles

    puts players.map { |p| [p.color, p.score] }.inspect
  end

protected

  def remove_killed_vehicles
    @players.each do |player|
      player.vehicles.reject! { |v| v.dead }
    end
  end

  def kill_colliding_vehicles
    @players.product(@players).each do |player_1, player_2|
      next if player_1 == player_2
      player_1.vehicles.product(player_2.vehicles).each do |vehicle_1, vehicle_2|
        vehicle_1.kill if vehicle_1.collided?(vehicle_2)
      end
    end
  end

  def capture_generators_and_kill_capturing_vehicles
    @generators.each do |generator|
      @players.each do |player|
        next if generator.owner?(player)
        player.vehicles.each do |vehicle|
          # FIXME: Create a `Generator.captured_by?` method
          if generator.contains?(vehicle.circle.x, vehicle.circle.y)
            generator.capture(player)
            vehicle.kill
          end
        end
      end
    end
  end
end
