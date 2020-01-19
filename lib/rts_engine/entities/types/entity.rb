class Entity
  attr_reader :position

  def initialize(position)
    @position = position
  end

  def x
    @position[0]
  end

  def x=(x)
    @position[0] = x
  end

  def y
    @position[1]
  end

  def y=(y)
    @position[1] = y
  end
end
