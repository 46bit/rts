require_relative '../entities/vehicle'
require_relative '../entities/projectile'

class Structure
  COLLISION_RADIUS = 1

  attr_reader :position, :player, :scale_factor

  def initialize(position, player: nil, scale_factor: 1.0)
    @position = position
    @player = player
    @scale_factor = scale_factor
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

  def scale(coordinate)
    coordinate * @scale_factor
  end
end
