require_relative './vehicle'

class Factory
  COST_OF_BUILDING_A_UNIT = 100
  DAMAGING_EVENTS = {
    vehicle_collision: 10,
  }

  attr_reader :position, :player, :health, :full_health
  attr_reader :factory_ready, :scale_factor, :unit_progress
  attr_reader :outline, :square, :progress_square, :health_bar

  def initialize(position, player, health: 100, factory_ready: true, scale_factor: 1.0)
    @position = position
    @player = player
    @health = health
    @full_health = 100
    @factory_ready = factory_ready
    @scale_factor = scale_factor
    @unit_progress = nil

    return if HEADLESS
    @outline = Square.new(
      x: (@position[0] - 9.5) * @scale_factor,
      y: (@position[1] - 9.5) * @scale_factor,
      size: @scale_factor * 19,
      color: @player.color,
      z: 1,
    )
    @square = Square.new(
      x: (@position[0] - 7.5) * @scale_factor,
      y: (@position[1] - 7.5) * @scale_factor,
      size: @scale_factor * 15,
      color: 'black',
      z: 2,
    )
    @progress_square = Square.new(
      x: (@position[0] - 7.5) * @scale_factor,
      y: (@position[1] - 7.5) * @scale_factor,
      size: @scale_factor * 15,
      color: @player.color,
      opacity: 0.0,
      z: 3,
    )
    @health_bar = Line.new(
      x1: (@position[0] - 9.5) * @scale_factor,
      y1: (@position[1] + 11) * @scale_factor,
      x2: (@position[0] + 9.5) * @scale_factor,
      y2: (@position[1] + 11) * @scale_factor,
      width: 1.5 * @scale_factor,
      color: @player.color,
      z: 2,
    )
  end

  def construct_new
    return unless @factory_ready
    @unit_progress ||= 0
  end

  def progress
    @unit_progress.to_f / COST_OF_BUILDING_A_UNIT
  end

  def vehicle_collided?(vehicle)
    distance = (@position - vehicle.position).magnitude
    distance <= 19.0
  end

  def dead?
    @health.zero?
  end

  def damaged?
    @health < @full_health
  end

  def healthyness
    @health.to_f / @full_health
  end

  def heal
    @health = [@full_health, @health + 20].min
    @factory_ready = true if @health == @full_health
  end

  def damage(cause)
    raise "damage type #{cause} not found on factory" unless DAMAGING_EVENTS.has_key?(cause)
    @health = [@health - DAMAGING_EVENTS[cause], 0].max
    if dead? && !HEADLESS
      @outline.remove
      @square.remove
      @progress_square.remove
      @health_bar.remove
    end
  end

  def update(build_capacity, can_produce: true)
    return unless @factory_ready
    return if @unit_progress.nil?

    @unit_progress += build_capacity
    return unless @unit_progress >= COST_OF_BUILDING_A_UNIT && can_produce

    @unit_progress = nil
    return Vehicle.new(
      @position,
      @player,
      scale_factor: @scale_factor,
    )
  end

  def render
    @health_bar.x2 = (@position[0] - 9.5 + 19 * healthyness) * @scale_factor
    @health_bar.width = healthyness > 0.5 ? 1.5 * @scale_factor : 2 * @scale_factor

    if @factory_ready
      @outline.opacity = 1.0
    else
      @outline.opacity = 0.2 + 0.8 * healthyness
    end

    if @unit_progress.nil?
      @progress_square.opacity = 0.0
    else
      @progress_square.opacity = 0.1 + 0.9 * progress
    end
  end
end
