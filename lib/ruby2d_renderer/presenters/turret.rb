require_relative "./types/unit"
require_relative "./types/projectile"

class TurretPresenter < UnitPresenter
  RADIUS = 5.0

  attr_reader :star

  def prerender
    super
    @star ||= @renderer.star(
      x: @entity.x,
      y: @entity.y,
      radius: RADIUS,
      color: @entity.player.color,
      opacity: @entity.built? ? 1.0 : (0.2 + @entity.healthyness * 0.8),
      z: 2,
    )
  end

  def render
    super
    @star.opacity = @entity.built? ? 1.0 : (0.2 + @entity.healthyness * 0.8)
  end

  def derender
    super
    @star&.remove
  end
end

class TurretProjectilePresenter < ProjectilePresenter
  def initialize(renderer, entity)
    super(renderer, entity, width: 6, length: 6, opacity: 0.7, z: 9999)
  end
end
