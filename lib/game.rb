if HEADLESS
  require_relative "./renderer/headless"
else
  require_relative "./renderer/renderer"
end
require_relative "./units/generator"
require_relative "./player"
require_relative "./quadtree"

class Game
  def self.from_config(config, screen_size: 800)
    renderer = Renderer.new(screen_size, config.fetch("world_size"))

    generators = config.fetch("generators").map do |generator_config|
      Generator::from_config(generator_config, renderer)
    end
    players = config.fetch("players").map do |player_config|
      Player::from_config(player_config, config.fetch("unit_cap"), renderer, generators)
    end
    Game.new(
      renderer,
      generators,
      players,
      sandbox: config.fetch("sandbox", false),
    )
  end

  attr_reader :renderer, :generators, :players, :sandbox, :update_counter, :winner

  def initialize(renderer, generators, players, sandbox: false)
    @renderer = renderer
    @generators = generators
    @players = players
    @sandbox = sandbox
    @update_counter = 0
    @winner = false
    @latest_update_duration = nil
    @latest_game_update_duration = nil
    @latest_players_update_duration = nil
  end

  def update
    @latest_update_duration = time do
      @update_counter += 1

      @latest_game_update_duration = time do
        units = @players.map(&:units).flatten
        unit_quadtree = Quadtree.from_units(units)

        damage_enemy_things_that_projectiles_collide_with(unit_quadtree)
        remove_killed_projectiles
        capture_generators_and_damage_capturing_vehicles(unit_quadtree)
        remove_killed_vehicles
        damage_colliding_units(unit_quadtree)
        remove_killed_vehicles
        remove_killed_factories
      end

      @latest_players_update_duration = time do
        @players.each do |player|
          player.update(@generators, @players - [player])
        end
        remove_killed_vehicles
        remove_killed_projectiles
      end

      @generators.each do |generator|
        generator.player = nil if generator.player && generator.player.defeated?
      end

      check_for_winner unless @sandbox || @winner
    end
  end

  def render
    @latest_render_duration = time do
      @generators.each(&:render)
      @players.each(&:render)

      if @winner
        exit 0 if Time.now - @win_time > 5
        unless @label
          @label = @renderer.text(
            "#{@winner} wins!",
            x: @renderer.world_size / 2,
            y: @renderer.world_size / 2,
            size: 100,
            color: "white",
            z: 10,
          )
          @label.align_centre
          @label.align_middle
        end
      end
    end
  end

  def status
    {
      update_counter: @update_counter,
      winner: @winner,
      players: @players.map do |player|
        {
          color: player.color,
          defeated: player.defeated?,
          unit_count: player.unit_count,
        }
      end,
    }
  end

  def status_text
    text = %(---
update_counter: #{@update_counter}
winner: #{@winner}
update_duration: #{@latest_update_duration}
render_duration: #{@latest_render_duration}
game_update_duration: #{@latest_game_update_duration}
players_update_duration: #{@latest_players_update_duration}
players:)
    players.each do |player|
      text += %(
- color: #{player.color}
  defeated: #{player.defeated?}
  unit_count: #{player.unit_count}
  update_duration: #{player.latest_update_duration}
  render_duration: #{player.latest_render_duration})
    end
    text
  end

protected

  def check_for_winner
    return if @winner

    undefeated_players = @players.reject(&:defeated?)
    if undefeated_players.empty?
      @winner = "nobody"
    elsif undefeated_players.length == 1
      @winner = undefeated_players[0].color
    end

    @win_time = Time.now if @winner
  end

  def remove_killed_vehicles
    @players.each do |player|
      player.vehicles.reject!(&:dead)
    end
  end

  def remove_killed_factories
    @players.each do |player|
      player.factories.reject!(&:dead?)
    end
  end

  def remove_killed_projectiles
    @players.each do |player|
      player.projectiles.reject!(&:dead)
    end
  end

  def damage_enemy_things_that_projectiles_collide_with(unit_quadtree)
    @players.each do |player|
      next if player.projectiles.empty?

      unit_quadtree.collisions(player.projectiles).each do |projectile, enemy_units|
        damage_per_enemy = projectile.damage.to_f / enemy_units.length
        enemy_units.each do |enemy_unit|
          enemy_unit.damage(damage_per_enemy)
        end
        projectile.kill
      end
    end
  end

  def damage_colliding_units(unit_quadtree)
    orig_unit_health = Hash[@players.map(&:units).flatten.map { |v| [v.object_id, v.health] }]

    @players.each do |player|
      unit_quadtree.collisions(player.units).each do |player_unit, enemy_units|
        damage_per_enemy = orig_unit_health[player_unit.object_id] / enemy_units.length
        enemy_units.each do |enemy_unit|
          enemy_unit.damage(damage_per_enemy)
        end
      end
    end
  end

  def capture_generators_and_damage_capturing_vehicles(unit_quadtree)
    unit_quadtree.collisions(@generators).each do |generator, colliding_units|
      # What to do here is awkward. The least biased thing to do is randomly pick an enemy colliding unit
      # and say that won…
      colliding_units.shuffle!
      generator.capture(colliding_units[0].player)
      colliding_units[0].damage(10)
    end
  end
end
