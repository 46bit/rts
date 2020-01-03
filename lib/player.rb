require_relative './player_ai'

class Player
  attr_reader :color, :control, :unit_cap, :base_generation_capacity, :factories, :vehicles, :score

  def initialize(color, control, unit_cap: nil, base_generation_capacity: 1.0)
    @color = color
    @control = control
    @unit_cap = unit_cap
    @base_generation_capacity = base_generation_capacity
    @factories = []
    @vehicles = []
    @score = 0
  end

  def add_factory(factory)
    @factories << factory
  end

  def update(generators, other_players)
    build_capacity = build_capacity(generators)
    if !@unit_cap.nil? && @vehicles.length >= @unit_cap
      build_capacity = 0
    end
    build_capacity_per_factory = build_capacity.to_f / @factories.length

    @factories.each do |factory|
      vehicle = factory.update(build_capacity_per_factory)
      unless vehicle.nil?
        @vehicles << vehicle
        @score += 1
      end
    end

    @control.update(generators, self, other_players)
    @vehicles.reject! { |v| v.dead }
  end

  def render
    @factories.each(&:render)
    @vehicles.each(&:render)
  end

  def build_capacity(generators)
    owned_generators = generators.select { |g| g.owner?(self) }
    owned_generation_capacity = owned_generators.map { |g| g.capacity }.sum
    return @base_generation_capacity + owned_generation_capacity
  end
end
