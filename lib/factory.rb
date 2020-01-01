require_relative './vehicle_renderer'

class Factory
  attr_reader :position, :build_time, :scale_factor, :velocity_scale_factor, :vehicle_class
  attr_reader :construction_progress

  def initialize(position, build_time: 10, scale_factor: 1.0, velocity_scale_factor: 1.0, vehicle_class: VehicleRenderer)
    @position = position
    @build_time = build_time
    @scale_factor = scale_factor
    @velocity_scale_factor = velocity_scale_factor
    @vehicle_class = vehicle_class
    @construction_progress = nil
  end

  def construct_new
    @construction_progress ||= 0
  end

  def progress
    @construction_progress.to_f / @build_time
  end

  def tick(build_capacity)
    return if @construction_progress.nil?

    @construction_progress += build_capacity
    if @construction_progress >= @build_time
      @construction_progress = nil
      return @vehicle_class.new(
        position: @position,
        direction: rand * Math::PI * 2,
        scale_factor: @scale_factor,
        velocity_scale_factor: @velocity_scale_factor,
      )
    end
  end
end
