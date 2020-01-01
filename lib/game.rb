require 'matrix'
require_relative './generator_renderer'
require_relative './factory_renderer'
require_relative './player_renderer'

class Game
  def self.from_config(config, screen_size: 800)
    scale_factor = screen_size.to_f / config["size"]
    velocity_scale_factor = 0.075

    generators = config["generators"].map do |g|
      GeneratorRenderer.new(
        Vector[g["x"], g["y"]],
        capacity: g["capacity"],
        scale_factor: scale_factor,
      )
    end

    players = config["players"].map do |p|
      PlayerRenderer.new(
        p["color"],
        FactoryRenderer.new(
          Vector[p["x"], p["y"]],
          color: p["color"],
          build_time: config["build_time"],
          scale_factor: scale_factor,
          velocity_scale_factor: velocity_scale_factor,
        ),
        unit_cap: config["unit_cap"],
      )
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
      player.factory.construct_new
      player.tick(@generators, @players - [player])
    end
    remove_killed_vehicles
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
