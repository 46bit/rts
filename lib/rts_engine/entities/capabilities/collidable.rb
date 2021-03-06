module Collidable
  attr_reader :collision_radius

  def initialize_collidable(collision_radius:)
    @collision_radius = collision_radius
  end

  def collided?(object, within: 0)
    combined_collision_radius = @collision_radius + object.collision_radius + within
    distance_between = (object.position - @position).magnitude
    distance_between <= combined_collision_radius
  end
end
