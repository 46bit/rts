require_relative "./entity"
require_relative "../capabilities/ownable"
require_relative "../capabilities/buildable"
require_relative "../capabilities/collidable"
require_relative "../capabilities/presentable"

class Structure < Entity
  include Ownable
  include Buildable
  include Collidable
  include Presentable

  attr_reader :icon

  def initialize(renderer, position, player, max_health:, health: nil, built: false, cost: max_health * 10, collision_radius:)
    super(position)
    initialize_ownable(player: player)
    initialize_buildable(max_health: max_health, health: health, built: built, cost: cost)
    initialize_collidable(collision_radius: collision_radius)
    initialize_presentable(renderer)
  end

  def self.buildable_by_mobile_units?
    true
  end
end
