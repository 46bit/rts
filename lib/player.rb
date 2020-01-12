require_relative './ai'
require_relative './units/commander'

class Player
  def self.from_config(player_config, unit_cap, renderer, generators)
    # FIXME: generators shouldn't be passed here. rethink the AI structure.
    ai = ai_from_string(player_config["control"], renderer.world_size, generators)
    raise "no AI found for player configured to use '#{player_config["control"]}'" unless ai
    Player.new(
      player_config["color"],
      ai,
      renderer,
      Vector[
        player_config["x"],
        player_config["y"],
      ],
      unit_cap: unit_cap,
    )
  end

  attr_reader :color, :control, :unit_cap, :base_generation_capacity, :renderer
  attr_accessor :energy, :factories, :vehicles, :turrets, :projectiles, :constructions, :commander

  def initialize(color, control, renderer, commander_position, unit_cap: Float::INFINITY, base_generation_capacity: 5)
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
    @constructions = []
    @commander = Commander.new(
      @renderer,
      commander_position,
      self,
    )
    @vehicles << @commander
  end

  def update(generators, other_players)
    remove_dead_units

    if defeated?
      @constructions.each(&:kill)
      @constructions = []
      return
    end

    update_energy_generation(generators)
    update_energy_consumption
    @factories.each(&:update)
    @vehicles.each(&:update)
    update_constructions
    update_turrets_and_projectiles(other_players)
    remove_dead_units

    @control.update(generators, self, other_players)
    remove_dead_units
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
      @stats_text.text = "#{unit_count}/#{@unit_cap} #{@energy.round}+#{pretty_build_capacity}"
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
    @factories + @vehicles + @turrets + @constructions
  end

  def defeated?
    unit_count == 0 && @projectiles.empty?
  end

protected

  def remove_dead_units
    @vehicles.reject! { |v| v.dead? }
    @projectiles.reject! { |v| v.dead? }
    @turrets.reject! { |v| v.dead? }
    @constructions.reject! { |c| c.dead? }
  end

  def update_energy_generation(generators)
    owned_generators = generators.select { |g| g.owner?(self) }
    owned_generation_capacity = owned_generators.map { |g| g.capacity }.sum
    @latest_build_capacity = @base_generation_capacity.to_f + owned_generation_capacity
    @energy += @latest_build_capacity
  end

  def update_energy_consumption
    powered_units = @factories.select(&:producing?)
    powered_units += @vehicles.select { |u| u.respond_to?(:producing?) && u.producing? }
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
      powered_unit.energy_provided = power_drain
      @energy -= power_drain
    end
  end

  def update_constructions
    @constructions.each do |construction|
      break if unit_count >= @unit_cap
      next if !construction.built?

      @constructions.delete(construction)
      construction.prerender
      case construction
      when Factory
        @factories << construction
      when Turret
        @turrets << construction
      else
        raise "unknown unit construction complete: '#{construction}'" unless construction.class.ancestors.include?(Vehicle)
        @vehicles << construction
      end
    end
  end

  def update_turrets_and_projectiles(other_players)
    enemy_vehicles = other_players.map(&:units).flatten
    @turrets.each do |turret|
      projectile = turret.update(enemy_vehicles)
      @projectiles << projectile unless projectile.nil?
    end
    @projectiles.each(&:update)
  end
end
