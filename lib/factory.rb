require_relative './vehicle'

DEFAULT_DAMAGES = {
  vehicle_collision: 10,
}

class Factory
  attr_reader :position, :player, :build_time, :scale_factor
  attr_reader :health, :full_health, :damages, :construction_progress
  attr_reader :outline, :square, :progress_square, :health_bar

  def initialize(position, player, build_time: 10, scale_factor: 1.0, health: 100, damages: DEFAULT_DAMAGES)
    @position = position
    @player = player
    @build_time = build_time
    @scale_factor = scale_factor
    @health = health
    @full_health = health.clone
    @damages = damages
    @construction_progress = nil

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
    @construction_progress ||= 0
  end

  def progress
    @construction_progress.to_f / @build_time
  end

  def vehicle_collided?(vehicle)
    distance = (@position - vehicle.position).magnitude
    distance <= 19.0
  end

  def dead?
    @health.zero?
  end

  def damage(cause)
    raise "damage type #{cause} not found on factory" unless @damages.has_key?(cause)
    @health = [@health - @damages[cause], 0].max
    if dead?
      @outline.remove
      @square.remove
      @progress_square.remove
      @health_bar.remove
    end
  end

  def update(build_capacity)
    return if @construction_progress.nil?

    @construction_progress += build_capacity
    return unless @construction_progress >= @build_time

    @construction_progress = nil
    return Vehicle.new(
      @position,
      @player,
      scale_factor: @scale_factor,
    )
  end

  def render
    health_proportion = @health.to_f / @full_health
    @health_bar.x2 = (@position[0] - 9.5 + 19 * health_proportion) * @scale_factor
    @health_bar.width = health_proportion > 0.5 ? 1.5 * @scale_factor : 2 * @scale_factor

    if @construction_progress.nil?
      @progress_square.opacity = 0.0
    else
      @progress_square.opacity = 0.1 + 0.9 * progress
    end
  end
end
