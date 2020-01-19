require_relative "./types/location"
require_relative "./capabilities/presentable"

class PowerSource < Location
  def self.from_config(power_source_config, renderer)
    PowerSource.new(
      renderer,
      Vector[
        power_source_config["x"],
        power_source_config["y"],
      ],
    )
  end

  include Presentable

  attr_reader :structure

  def initialize(renderer, position, structure: nil)
    super(position, collision_radius: 7)
    @structure = structure
    initialize_presentable(renderer)
  end

  def structure=(structure)
    if @structure&.alive?
      raise "trying to build on power source at '#{@position}' when a structure '#{@structure}' is already on it"
    elsif !structure || structure.position == @position
      @structure = structure
    else
      raise "structure position '#{structure.position}' did not match power source position '#{@position}'"
    end
  end

  def update
    @structure = nil if @structure&.dead?
  end

  def owner?(player)
    @structure && @structure.player == player
  end

  def occupied?
    !!@structure&.player
  end
end
