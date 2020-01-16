require_relative "./entity"

class ProjectilePresenter < EntityPresenter
  attr_reader :width, :length, :opacity, :z, :teardrop

  def initialize(renderer, entity, width:, length:, opacity:, z:)
    super(renderer, entity)
    @width = width
    @length = length
    @opacity = opacity
    @z = z
  end

  def prerender
    super
    @teardrop ||= @renderer.teardrop(
      x: @entity.x,
      y: @entity.y,
      direction: @entity.direction,
      width: @width,
      length: @length,
      color: @entity.player.color,
      opacity: @opacity,
      z: @z,
    )
  end

  def render
    super
    @teardrop.x = @entity.x
    @teardrop.y = @entity.y
  end

  def derender
    super
    @teardrop&.remove
  end
end
