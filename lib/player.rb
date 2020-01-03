require_relative './player_ai'

class Player
  attr_reader :color, :control, :unit_cap, :base_generation_capacity
  attr_reader :factories, :vehicles, :projectiles, :score

  def initialize(color, control, unit_cap: Float::INFINITY, base_generation_capacity: 1.0)
    @color = color
    @control = control
    @unit_cap = unit_cap
    @base_generation_capacity = base_generation_capacity
    @factories = []
    @vehicles = []
    @projectiles = []
    @score = 0
  end

  def add_factory(factory)
    @factories << factory
  end

  def add_projectile(projectile)
    @projectiles << projectile
  end

  def update(generators, other_players)
    @latest_build_capacity = build_capacity(generators)
    build_capacity_per_factory = @latest_build_capacity.to_f / @factories.length

    @factories.each do |factory|
      vehicle = factory.update(build_capacity_per_factory, can_produce: @vehicles.length < @unit_cap)
      unless vehicle.nil?
        @vehicles << vehicle
        @score += 1
      end
    end

    @projectiles.each(&:update)

    @control.update(generators, self, other_players)
    @vehicles.reject! { |v| v.dead }
  end

  def render
    @factories.each(&:render)
    @vehicles.each(&:render)
    @projectiles.each(&:render)

    oldest_factory = @factories[0]
    if oldest_factory
      if @stats_text.nil?
        @stats_text = Text.new(
          "",
          size: 8 * oldest_factory.scale_factor,
          color: @color,
          z: 2,
        )
      end
      pretty_build_capacity = @latest_build_capacity == @latest_build_capacity.to_i ? @latest_build_capacity.to_i : @latest_build_capacity
      @stats_text.text = "#{@vehicles.length}/#{@unit_cap} +#{pretty_build_capacity}"
      @stats_text.x = (oldest_factory.position[0] - 9.5) * oldest_factory.scale_factor
      @stats_text.y = (oldest_factory.position[1] + 14) * oldest_factory.scale_factor
    else
      @stats_text.remove unless @stats_text.nil?
      @stats_text = nil
    end
  end

  def build_capacity(generators)
    owned_generators = generators.select { |g| g.owner?(self) }
    owned_generation_capacity = owned_generators.map { |g| g.capacity }.sum
    return @base_generation_capacity + owned_generation_capacity
  end
end
