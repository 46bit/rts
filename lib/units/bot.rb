require_relative '../entities/vehicle'

class Bot < Vehicle
  RADIUS = 5.0
  SACRIFICIAL_REPAIR_VALUE = 20

  attr_reader :circle, :line

  def initialize(renderer, position, player, direction: rand * Math::PI * 2, built: true)
    super(
      renderer,
      position,
      player,
      max_health: 10,
      built: built,
      health: built ? 10 : 0,
      direction: direction,
      movement_rate: 0.1,
      turn_rate: 4.0/3.0,
      collision_radius: 5.0,
    )
    prerender unless HEADLESS || !built
  end

  def construct_structure(structure_class, **kargs)
    return false if @dead
    kill
    structure = structure_class.new(
      @renderer,
      @position,
      @player,
      built: false,
      **kargs
    )
    structure.repair(SACRIFICIAL_REPAIR_VALUE)
    return structure
  end

  def repair_structure(structure)
    return false if @dead || !structure.collided?(self)
    kill
    structure.repair(SACRIFICIAL_REPAIR_VALUE)
  end

  def kill
    super
    return if HEADLESS
    @circle.remove
    @line.remove
  end

  def prerender
    @circle = @renderer.circle(
      x: @position[0] - (RADIUS / 2.0),
      y: @position[1] - (RADIUS / 2.0),
      radius: RADIUS,
      color: @player.color,
      segments: 20,
      z: 2,
    )
    v = vector_from_magnitude_and_direction(RADIUS, @direction)
    @line = @renderer.line(
      x1: @position[0],
      y1: @position[1],
      x2: @position[0] + v[0],
      y2: @position[1] + v[1],
      width: 3,
      color: 'black',
      z: 2,
    )
  end

  def render
    return if @dead

    @circle.x = @position[0]
    @circle.y = @position[1]

    v = vector_from_magnitude_and_direction(RADIUS, @direction)
    @line.x1 = @position[0]
    @line.y1 = @position[1]
    @line.x2 = @position[0] + v[0]
    @line.y2 = @position[1] + v[1]
  end
end
