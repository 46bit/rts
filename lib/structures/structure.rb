require_relative '../entities/vehicle'
require_relative '../entities/projectile'

class Structure
  COLLISION_RADIUS = 1

  attr_reader :position, :player, :renderer

  def initialize(position, player, renderer)
    @position = position
    @player = player
    @renderer = renderer
  end

  def collided?(object)
    self.class::COLLISION_RADIUS + object.class::COLLISION_RADIUS >= (object.position - @position).magnitude
  end

  def owner?(player)
    @player == player
  end

  def occupied?
    !@player.nil?
  end

  def capture(player)
    @player = player
  end

  def update
  end

  def prerender
  end

  def render
  end
end
