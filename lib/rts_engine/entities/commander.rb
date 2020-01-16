require_relative "./types/engineer"

class Commander < Engineer
  def initialize(renderer, position, player, direction: rand * Math::PI * 2)
    super(
      renderer,
      position,
      player,
      max_health: 1000,
      built: true,
      direction: direction,
      movement_rate: 0.03,
      turn_rate: 2.0 / 3.0,
      collision_radius: 8.0,
      production_range: 35.0,
    )
  end
end
