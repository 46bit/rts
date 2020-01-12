if HEADLESS
  require_relative './renderer/headless'
else
  require_relative './renderer/renderer'
end
require_relative './units/generator'
require_relative './player'
require_relative './quadtree'

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
    units = @players.map(&:units).flatten
    unit_quadtree = Quadtree.from_units(units)

    damage_enemy_things_that_projectiles_collide_with(unit_quadtree)
    remove_killed_projectiles
    capture_generators_and_damage_capturing_vehicles(unit_quadtree)
    remove_killed_vehicles
    damage_colliding_units(unit_quadtree)
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
