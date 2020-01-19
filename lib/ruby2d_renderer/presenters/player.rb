require_relative "./types/entity"

class PlayerPresenter < EntityPresenter
  attr_reader :stats_text

  def prerender
    super

    @stats_text ||= @renderer.text(
      "",
      size: 14,
      color: @entity.color,
      z: 2,
    )
  end

  def render
    super
    oldest_factory = @entity.factories[0]
    if oldest_factory
      pretty_build_capacity = @entity.latest_build_capacity == @entity.latest_build_capacity.to_i ? @entity.latest_build_capacity.to_i : @entity.latest_build_capacity
      @stats_text.text = "#{@entity.unit_count}/#{@entity.unit_cap} #{@entity.energy.round}+#{pretty_build_capacity}"
      @stats_text.x = oldest_factory.x - 9.5
      @stats_text.y = oldest_factory.y + 14
      @stats_text.add
    else
      @stats_text.remove
    end
  end

  def derender
    super
    @stats_text&.remove
  end
end
