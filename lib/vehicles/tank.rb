require_relative './vehicle'

class Tank < Vehicle
  MOVEMENT_RATE = 0.05
  TURN_RATE = 4.0/6.0
  COLLISION_RADIUS = 8
  RADIUS = 8.0

  attr_reader :circle, :square, :line

  def initialize(*)
    super

    return if HEADLESS
    @circle = @renderer.circle(
      x: @position[0],
      y: @position[1],
      radius: RADIUS,
      color: @player.color,
      segments: 20,
      z: 2,
    )
    vector_to_point_on_circle = vector_from_magnitude_and_direction(RADIUS, @direction + Math::PI / 2)
    vector_to_front_of_unit = vector_from_magnitude_and_direction(RADIUS + 2, @direction)
    @square = @renderer.quad(
      x1: @position[0] + vector_to_point_on_circle[0],
      y1: @position[1] + vector_to_point_on_circle[1],
      x2: @position[0] + vector_to_point_on_circle[0] + vector_to_front_of_unit[0],
      y2: @position[1] + vector_to_point_on_circle[1] + vector_to_front_of_unit[1],
      x3: @position[0] - vector_to_point_on_circle[0] + vector_to_front_of_unit[0],
      y3: @position[1] - vector_to_point_on_circle[1] + vector_to_front_of_unit[1],
      x4: @position[0] - vector_to_point_on_circle[0],
      y4: @position[1] - vector_to_point_on_circle[1],
      color: @player.color,
      z: 2,
    )
    @line = @renderer.line(
      x1: @position[0],
      y1: @position[1],
      x2: @position[0] + vector_to_front_of_unit[0],
      y2: @position[1] + vector_to_front_of_unit[1],
      width: RADIUS / 2.0,
      color: 'black',
      z: 2,
    )
  end

  def kill
    super
    return if HEADLESS
    @circle.remove
    @square.remove
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

    vector_to_point_on_circle = vector_from_magnitude_and_direction(RADIUS, @direction + Math::PI / 2)
    vector_to_front_of_unit = vector_from_magnitude_and_direction(RADIUS + 2, @direction)
    @square.x1 = @position[0] + vector_to_point_on_circle[0]
    @square.y1 = @position[1] + vector_to_point_on_circle[1]
    @square.x2 = @position[0] + vector_to_point_on_circle[0] + vector_to_front_of_unit[0]
    @square.y2 = @position[1] + vector_to_point_on_circle[1] + vector_to_front_of_unit[1]
    @square.x3 = @position[0] - vector_to_point_on_circle[0] + vector_to_front_of_unit[0]
    @square.y3 = @position[1] - vector_to_point_on_circle[1] + vector_to_front_of_unit[1]
    @square.x4 = @position[0] - vector_to_point_on_circle[0]
    @square.y4 = @position[1] - vector_to_point_on_circle[1]

    @line.x1 = @position[0]
    @line.y1 = @position[1]
    @line.x2 = @position[0] + vector_to_front_of_unit[0]
    @line.y2 = @position[1] + vector_to_front_of_unit[1]
  end
end
