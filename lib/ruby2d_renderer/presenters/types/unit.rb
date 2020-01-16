require_relative "./entity"

class UnitPresenter < EntityPresenter
  attr_reader :health_bar

  def prerender
    super
    @health_bar ||= @renderer.line(
      x1: @entity.x - self.class::RADIUS,
      y1: @entity.y + self.class::RADIUS + 3,
      x2: @entity.x + self.class::RADIUS,
      y2: @entity.y + self.class::RADIUS + 3,
      width: 1.5,
      color: @entity.player.color,
      z: 9998,
    )
  end

  def render
    super
    if @entity.damaged?
      @health_bar.x1 = @entity.x - self.class::RADIUS
      @health_bar.y1 = @entity.y + self.class::RADIUS + 3
      @health_bar.x2 = @entity.x - self.class::RADIUS + 2 * self.class::RADIUS * @entity.healthyness
      @health_bar.y2 = @entity.y + self.class::RADIUS + 3
      @health_bar.width = @entity.healthyness > 0.5 ? 1.5 : 2
      @health_bar.add
    else
      @health_bar.remove
    end
  end

  def derender
    super
    @health_bar&.remove
  end
end
