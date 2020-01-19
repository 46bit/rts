require_relative "./unit"

class EngineerPresenter < UnitPresenter
  attr_reader :build_beam

  def prerender
    super
    @build_beam ||= @renderer.line(
      x1: 0,
      y1: 0,
      x2: 300,
      y2: 300,
      width: 1,
      color: @entity.player.color,
      z: 1,
    )
    @build_beam.remove
  end

  def render
    super
    if @entity.unit.nil? || !@entity.within_production_range?(@entity.unit.position)
      @build_beam.remove
    else
      @build_beam.add
      @build_beam.x1 = @entity.x
      @build_beam.y1 = @entity.y
      @build_beam.x2 = @entity.unit.x
      @build_beam.y2 = @entity.unit.y
    end
  end

  def derender
    super
    @build_beam&.remove
  end
end
