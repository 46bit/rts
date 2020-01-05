require_relative './ai'

class Player
  def self.from_config(player_config, unit_cap, renderer, generators)
    # FIXME: generators shouldn't be passed here. rethink the AI structure.
    ai = ai_from_string(player_config["control"], renderer.world_size, generators)
    raise "no AI found for player configured to use '#{player_config["control"]}'" unless ai
    player = Player.new(player_config["color"], ai, renderer, unit_cap: unit_cap)
    player.factories << Factory.new(
      Vector[
        player_config["x"],
        player_config["y"]
      ],
      player,
      renderer,
      built: true,
    )
    return player
  end

  attr_reader :color, :control, :unit_cap, :base_generation_capacity, :renderer
  attr_accessor :factories, :vehicles, :turrets, :projectiles

  def initialize(color, control, renderer, unit_cap: Float::INFINITY, base_generation_capacity: 1.0)
    @color = color
    @control = control
    @renderer = renderer
    @unit_cap = unit_cap
    @base_generation_capacity = base_generation_capacity
    @factories = []
    @vehicles = []
    @turrets = []
    @projectiles = []
  end

  def update(generators, other_players)
    @latest_build_capacity = build_capacity(generators)
    build_capacity_per_factory = @latest_build_capacity.to_f / @factories.length
    @factories.each do |factory|
      # FIXME: do something with unused_build_capacity
      unused_build_capacity, vehicle = factory.update(build_capacity_per_factory, can_produce: unit_count < @unit_cap)
      unless vehicle.nil?
        @vehicles << vehicle
      end
    end

    enemy_vehicles = (other_players.map(&:vehicles) + other_players.map(&:factories) + other_players.map(&:turrets)).flatten
    @turrets.each do |turret|
      projectile = turret.update(enemy_vehicles)
      @projectiles << projectile unless projectile.nil?
    end
    @projectiles.each(&:update)

    @control.update(generators, self, other_players)

    @vehicles.reject! { |v| v.dead }
    @projectiles.reject! { |v| v.dead }
    @turrets.reject! { |v| v.dead }
  end

  def render
    @factories.each(&:render)
    @vehicles.each(&:render)
    @turrets.each(&:render)
    @projectiles.each(&:render)

    oldest_factory = @factories[0]
    if oldest_factory
      if @stats_text.nil?
        @stats_text = @renderer.text(
          "",
          size: 8,
          color: @color,
          z: 2,
        )
      end
      pretty_build_capacity = @latest_build_capacity == @latest_build_capacity.to_i ? @latest_build_capacity.to_i : @latest_build_capacity
      @stats_text.text = "#{unit_count}/#{@unit_cap} +#{pretty_build_capacity}"
      @stats_text.x = (oldest_factory.position[0] - 9.5)
      @stats_text.y = (oldest_factory.position[1] + 14)
    else
      @stats_text.remove unless @stats_text.nil?
      @stats_text = nil
    end
  end

  def unit_count
    @factories.length + @vehicles.length + @turrets.length
  end

  def build_capacity(generators)
    owned_generators = generators.select { |g| g.owner?(self) }
    owned_generation_capacity = owned_generators.map { |g| g.capacity }.sum
    return @base_generation_capacity + owned_generation_capacity
  end
end
