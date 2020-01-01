require_relative './player_ai'

class Player
  attr_reader :color, :factory, :unit_cap, :base_generation_capacity, :control, :vehicles

  def initialize(color, factory, unit_cap: nil, base_generation_capacity: 1.0, control: PlayerAI.new)
    @color = color
    @factory = factory
    @unit_cap = unit_cap
    @base_generation_capacity = base_generation_capacity
    @control = control
    @vehicles = []
  end

  def tick(generators, other_players)
    build_capacity = build_capacity(generators)
    if !@unit_cap.nil? && @vehicles.length >= @unit_cap
      build_capacity = 0
    end

    vehicle = @factory.tick(build_capacity)
    unless vehicle.nil?
      vehicle.color = @color
      @vehicles << vehicle
    end

    @control.tick(generators, self, other_players)
    @vehicles.reject! { |v| v.dead }
  end

  def build_capacity(generators)
    owned_generators = generators.select { |g| g.owner?(self) }
    owned_generation_capacity = owned_generators.map { |g| g.capacity }.sum
    return @base_generation_capacity + owned_generation_capacity
  end
end
