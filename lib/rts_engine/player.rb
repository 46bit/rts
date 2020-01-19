require_relative "../utils"
require_relative "./ai"
require_relative "./entities/commander"

class Player
  def self.from_config(player_config, unit_cap, renderer, power_sources)
    # FIXME: power sources shouldn't be passed here. rethink the AI structure.
    ai = ai_from_string(player_config["control"], renderer.world_size, power_sources)
    raise "no AI found for player configured to use '#{player_config['control']}'" unless ai

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

  attr_reader :presenter, :color, :control, :unit_cap, :base_generation_capacity, :renderer, :latest_build_capacity, :latest_update_duration, :latest_render_duration
  attr_accessor :energy, :factories, :vehicles, :turrets, :projectiles, :constructions, :commander, :enemy_units

  def initialize(color, control, renderer, commander_position, unit_cap: Float::INFINITY, base_generation_capacity: 5)
    @presenter = renderer.present(self)
    @color = color
    @control = control
    @renderer = renderer
    @unit_cap = unit_cap
    @base_generation_capacity = base_generation_capacity
    @latest_build_capacity = base_generation_capacity
    @energy = 0.0
    @factories = []
    @vehicles = []
    @turrets = []
    @generators = []
    @projectiles = []
    @constructions = []
    @commander = Commander.new(
      @renderer,
      commander_position,
      self,
    )
    @vehicles << @commander
    @enemy_units = []
    @latest_update_duration = nil
    @latest_render_duration = nil
  end

  def update(power_sources, other_players)
    @latest_update_duration = time do
      remove_dead_units

      if defeated?
        @constructions.each(&:kill)
        @constructions = []
        return
      end

      @enemy_units = other_players.map(&:units).flatten

      update_energy_generation(power_sources)
      update_energy_consumption
      @factories.each(&:update)
      @vehicles.each(&:update)
      update_constructions
      @turrets.each(&:update)
      @projectiles.each(&:update)
      remove_dead_units

      @control.update(power_sources, self, other_players)
      remove_dead_units
    end
  end

  def render
    @latest_render_duration = time do
      @presenter.prerender
      @presenter.render
      @generators.each(&:present)
      @factories.each(&:present)
      @vehicles.each(&:present)
      @turrets.each(&:present)
      @constructions.each(&:present)
      @projectiles.each(&:present)
    end
  end

  def unit_count
    @factories.length + @vehicles.length + @turrets.length
  end

  def units
    @generators + @factories + @vehicles + @turrets + @constructions
  end

  def defeated?
    unit_count.zero? && @projectiles.empty?
  end

protected

  def remove_dead_units
    @generators.reject!(&:dead?)
    @vehicles.reject!(&:dead?)
    @projectiles.reject!(&:dead?)
    @turrets.reject!(&:dead?)
    @constructions.reject!(&:dead?)
  end

  def update_energy_generation(_power_sources)
    owned_generation_capacity = @generators.map(&:capacity).sum
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
      case construction
      when Generator
        @generators << construction
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
end
