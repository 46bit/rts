require_relative "./types/vehicle"

class Tank < Vehicle
  def initialize(renderer, position, player, direction: rand * Math::PI * 2, built: true)
    super(
      renderer,
      position,
      player,
      max_health: 200,
      built: built,
      direction: direction,
      movement_rate: 0.05,
      turn_rate: 2.0 / 3.0,
      collision_radius: 8.0,
    )
  end
end
