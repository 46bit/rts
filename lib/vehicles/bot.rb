require_relative './vehicle'

class Bot < Vehicle
  MOVEMENT_RATE = 0.1
  TURN_RATE = 4.0/3.0
  COLLISION_RADIUS = 5

  attr_reader :circle, :line

  def initialize(*)
    super

    return if HEADLESS
    @circle = @renderer.circle(
      x: @position[0] - 2.5,
      y: @position[1] - 2.5,
      radius: 5,
      color: @player.color,
      segments: 20,
      z: 2,
    )
    v = vector_from_magnitude_and_direction(5.0, @direction)
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

  def kill
    super
    return if HEADLESS
    @circle.remove
    @line.remove
  end

  def construct_structure(structure_class, **kargs)
    return false if @dead
    kill
    structure = structure_class.new(
      @position,
      @player,
      @renderer,
      **kargs
    )
    structure.heal(:vehicle_repair)
    return structure
  end

  def repair_structure(structure)
    return false if @dead || !structure.collided?(self)
    kill
    structure.heal(:vehicle_repair)
  end

  def render
    return if @dead

    @circle.x = @position[0]
    @circle.y = @position[1]

    v = vector_from_magnitude_and_direction(5.0, @direction)
    @line.x1 = @position[0]
    @line.y1 = @position[1]
    @line.x2 = @position[0] + v[0]
    @line.y2 = @position[1] + v[1]
  end
end
