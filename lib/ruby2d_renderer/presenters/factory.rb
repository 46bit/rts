require_relative "./types/unit"

class FactoryPresenter < UnitPresenter
  RADIUS = 8

  attr_reader :outline, :square, :progress_square

  def prerender
    super
    @outline ||= @renderer.square(
      x: @entity.x - 9.5,
      y: @entity.y - 9.5,
      size: 19,
      color: @entity.player.color,
      z: 1,
    )
    @square ||= @renderer.square(
      x: @entity.x - 7.5,
      y: @entity.y - 7.5,
      size: 15,
      color: "black",
      z: 2,
    )
    @progress_square ||= @renderer.square(
      x: @entity.x - 7.5,
      y: @entity.y - 7.5,
      size: 15,
      color: @entity.player.color,
      opacity: 0.0,
      z: 3,
    )
  end

  def render
    super
    @outline.opacity = @entity.built? ? 1.0 : (0.2 + @entity.healthyness * 0.7)
    @progress_square.opacity = @entity.unit.nil? ? 0.0 : (0.1 + @entity.production_progress * 0.9)
  end

  def derender
    super
    @outline&.remove
    @square&.remove
    @progress_square&.remove
  end
end
