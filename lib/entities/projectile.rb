require_relative '../utils'

class Projectile
  MOVEMENT_RATE = 3.5
  MAXIMUM_RANGE = 180
  COLLISION_RADIUS = 4

  attr_reader :position, :start_position, :direction, :renderer, :damage_type
  attr_reader :velocity, :dead, :teardrop

  def initialize(position, direction, color, renderer, damage_type: :projectile_collision)
    @position = position
    @start_position = position
    @direction = direction
    @renderer = renderer
    @damage_type = damage_type
    @velocity = MOVEMENT_RATE
    @dead = false

    return if HEADLESS
    @teardrop = @renderer.teardrop(
      x: @position[0],
      y: @position[1],
      direction: @direction,
      width: 6,
      length: 6,
      color: color,
      opacity: 0.7,
      z: 5,
    )
  end

  def kill
    @dead = true
    @teardrop.remove unless HEADLESS
  end

  def update
    return if @dead
    @position += vector_from_magnitude_and_direction(@velocity, @direction)
    kill if (@position - @start_position).magnitude > MAXIMUM_RANGE
  end

  def render
    return if @dead

    @teardrop.x = @position[0]
    @teardrop.y = @position[1]
  end
end
