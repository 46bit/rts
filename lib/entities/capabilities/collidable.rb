module Collidable
  attr_reader :collision_radius

  def initialize_collidable(collision_radius:)
    @collision_radius = collision_radius
  end

  def collided?(object)
    combined_collision_radius = @collision_radius + object.collision_radius
    distance_between = (object.position - @position).magnitude
    return distance_between <= combined_collision_radius
  end
end