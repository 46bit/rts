require_relative "./entity"

class UnitPresenter < EntityPresenter
  attr_reader :icon, :health_bar, :health_bar_bg

  def prerender
    super
    @icon ||= @renderer.icon(
      x: @entity.x,
      y: @entity.y,
      character: @entity.class.name.to_s[0],
      color: @entity.player.color,
      # Put the icons of the strongest units on top
      z: 9999 + @entity.max_health,
    )
    @health_bar ||= @renderer.line(
      x1: @entity.x - self.class::RADIUS,
      y1: @entity.y + self.class::RADIUS + 3,
      x2: @entity.x + self.class::RADIUS,
      y2: @entity.y + self.class::RADIUS + 3,
      width: 1.5,
      color: @entity.player.color,
      z: 9998,
    )
    @health_bar_bg ||= @renderer.line(
      x1: @entity.x - self.class::RADIUS,
      y1: @entity.y + self.class::RADIUS + 3,
      x2: @entity.x + self.class::RADIUS,
      y2: @entity.y + self.class::RADIUS + 3,
      width: 1.5,
      color: @entity.player.color,
      opacity: 0.1,
      z: 9998,
    )
  end

  def render
    super

    @icon.x = @entity.x
    @icon.y = @entity.y

    if @entity.damaged?
      @health_bar.x1 = @entity.x - self.class::RADIUS
      @health_bar.y1 = @entity.y + self.class::RADIUS + 3
      @health_bar.x2 = @entity.x - self.class::RADIUS + 2 * self.class::RADIUS * @entity.healthyness
      @health_bar.y2 = @entity.y + self.class::RADIUS + 3
      @health_bar.width = @entity.healthyness > 0.5 ? 1.5 : 2
      @health_bar.add
      @health_bar_bg.x1 = @entity.x - self.class::RADIUS
      @health_bar_bg.y1 = @entity.y + self.class::RADIUS + 3
      @health_bar_bg.x2 = @entity.x - self.class::RADIUS + 2 * self.class::RADIUS
      @health_bar_bg.y2 = @entity.y + self.class::RADIUS + 3
      @health_bar_bg.add
    else
      @health_bar.remove
      @health_bar_bg.remove
    end
  end

  def derender
    super
    @icon&.remove
    @health_bar&.remove
    @health_bar_bg&.remove
  end
end
