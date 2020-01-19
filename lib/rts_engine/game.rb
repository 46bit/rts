require_relative "./entities/power_source"
require_relative "./player"
require_relative "./quadtree"

class Game
  def self.from_config(config, renderer)
    power_sources = config.fetch("power_sources").map do |power_source_config|
      PowerSource::from_config(power_source_config, renderer)
    end
    players = config.fetch("players").map do |player_config|
      Player::from_config(player_config, config.fetch("unit_cap"), renderer, power_sources)
    end
    Game.new(
      renderer,
      power_sources,
      players,
      sandbox: config.fetch("sandbox", false),
    )
  end

  attr_reader :presenter, :renderer, :power_sources, :players, :sandbox, :update_counter, :winner, :win_time

  def initialize(renderer, power_sources, players, sandbox: false)
    @presenter = renderer.present(self)
    @renderer = renderer
    @power_sources = power_sources
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
        remove_killed_vehicles
        damage_colliding_units(unit_quadtree)
        remove_killed_vehicles
        remove_killed_factories

        @power_sources.each(&:update)
      end

      @latest_players_update_duration = time do
        @players.each do |player|
          player.update(@power_sources, @players - [player])
        end
        remove_killed_vehicles
        remove_killed_projectiles
      end

      check_for_winner unless @sandbox || @winner
    end
  end

  def render
    @latest_render_duration = time do
      @presenter.prerender
      @presenter.render
      @power_sources.each(&:present)
      @players.each(&:render)
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
        kill_projectile = false
        damage_per_enemy = projectile.damage.to_f / enemy_units.length
        enemy_units.each do |enemy_unit|
          kill_projectile ||= enemy_unit.health > 0
          enemy_unit.damage(damage_per_enemy)
        end
        projectile.kill if kill_projectile
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
end
