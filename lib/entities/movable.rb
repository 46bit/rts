require_relative '../utils'

module Movable
  attr_reader :velocity, :direction

  def update_position(multiplier: 1.0)
    @position += vector_from_magnitude_and_direction(@velocity * multiplier, @direction)
  end

  def going_south?
    @direction.abs < Math::PI / 2
  end

  def going_east?
    @direction > 0
  end
end
