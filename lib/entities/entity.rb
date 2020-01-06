require_relative '../utils'

class Entity
  attr_reader :renderer, :position

  def initialize(renderer, position)
    @renderer = renderer
    @position = position
  end
end
