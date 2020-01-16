require_relative "./types/engineer"

class Bot < Engineer
  def initialize(renderer, position, player, direction: rand * Math::PI * 2, built: true)
    super(
      renderer,
      position,
      player,
      max_health: 10,
      built: built,
      direction: direction,
      movement_rate: 0.1,
      turn_rate: 4.0 / 3.0,
      collision_radius: 5.0,
      production_range: 25.0,
    )
  end
end
