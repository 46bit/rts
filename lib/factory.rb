require_relative './vehicle'

class Factory
  attr_reader :position, :player, :build_time, :scale_factor
  attr_reader :construction_progress, :outline, :square, :progress_square

  def initialize(position, player, build_time: 10, scale_factor: 1.0)
    @position = position
    @player = player
    @build_time = build_time
    @scale_factor = scale_factor
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
  end

  def construct_new
    @construction_progress ||= 0
  end

  def progress
    @construction_progress.to_f / @build_time
  end

  def update(build_capacity)
    return if @construction_progress.nil?

    @construction_progress += build_capacity
    return unless @construction_progress >= @build_time

    @construction_progress = nil
    return Vehicle.new(
      @position,
      scale_factor: @scale_factor,
    )
  end

  def render
    if @construction_progress.nil?
      @progress_square.opacity = 0.0
    else
      @progress_square.opacity = 0.1 + 0.9 * progress
    end
  end
end
