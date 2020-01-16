class Entity
  attr_reader :renderer, :presenter, :position

  def initialize(renderer, position)
    @renderer = renderer
    @presenter = renderer.present(self)
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

  def render
    @presenter&.prerender
    @presenter&.render
  end
end
