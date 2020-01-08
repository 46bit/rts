require_relative './ai'

class Player
  def self.from_config(player_config, unit_cap, renderer, generators)
    # FIXME: generators shouldn't be passed here. rethink the AI structure.
    ai = ai_from_string(player_config["control"], renderer.world_size, generators)
    raise "no AI found for player configured to use '#{player_config["control"]}'" unless ai
    player = Player.new(player_config["color"], ai, renderer, unit_cap: unit_cap)
    player_config["factories"].each do |factory_config|
      player.factories << Factory.new(
        renderer,
        Vector[
          factory_config["x"],
          factory_config["y"]
        ],
        player,
        built: true,
      )
    end
    return player
  end

  attr_reader :color, :control, :unit_cap, :base_generation_capacity, :renderer
  attr_accessor :energy, :factories, :vehicles, :turrets, :projectiles

  def initialize(color, control, renderer, unit_cap: Float::INFINITY, base_generation_capacity: 1.0)
    @color = color
    @control = control
    @renderer = renderer
    @unit_cap = unit_cap
    @base_generation_capacity = base_generation_capacity
    @energy = 0.0
    @factories = []
    @vehicles = []
    @turrets = []
    @projectiles = []
  end

  def update(generators, other_players)
    update_energy(generators)

    powered_units = @factories.select(&:built?).select(&:producing?)
    power_drains = Hash[powered_units.map do |powered_unit|
      [powered_unit.object_id, powered_unit.energy_consumption]
    end]
    desired_energy_consumption = power_drains.values.sum
    if desired_energy_consumption > @energy
      power_per_unit = @energy / powered_units.length
      power_drains.transform_values! { power_per_unit }
    end
    at_unit_cap =  unit_count < @unit_cap
    powered_units.each do |powered_unit|
      # FIXME: do something with unused_build_capacity
      power_drain = power_drains[powered_unit.object_id]
      vehicle = powered_unit.update(power_drain, can_complete: at_unit_cap)
      @vehicles << vehicle unless vehicle.nil?
      @energy -= power_drain
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
      @stats_text.text = "#{unit_count}/#{@unit_cap} #{@energy}+#{pretty_build_capacity}"
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

  def units
    @factories + @vehicles + @turrets
  end

  def update_energy(generators)
    @latest_build_capacity = build_capacity(generators)
    @energy += @latest_build_capacity
  end

  def build_capacity(generators)
    owned_generators = generators.select { |g| g.owner?(self) }
    owned_generation_capacity = owned_generators.map { |g| g.capacity }.sum
    return @base_generation_capacity + owned_generation_capacity
  end
end
