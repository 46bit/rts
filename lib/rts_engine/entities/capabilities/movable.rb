require_relative "../../../utils"

module Movable
  attr_reader :velocity, :direction

  def initialize_movable(velocity: 0.0, direction: 0.0)
    @velocity = velocity
    @direction = direction
  end

  def update_position(multiplier: 1.0)
    @position += vector_from_magnitude_and_direction(@velocity * multiplier, @direction)
  end

  def going_south?
    @direction.abs < Math::PI / 2
  end

  def going_east?
    @direction.positive?
  end
end
