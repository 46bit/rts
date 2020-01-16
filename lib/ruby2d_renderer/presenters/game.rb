require_relative "./types/entity"

class GamePresenter < EntityPresenter
  attr_reader :label

  def prerender
    super
    @label ||= @renderer.text(
      "",
      x: @renderer.world_size / 2,
      y: @renderer.world_size / 2,
      size: 100,
      color: "white",
      z: 10,
    )
  end

  def render
    super

    if @entity.winner
      exit 0 if Time.now - @entity.win_time > 5

      if @label.text == ""
        @label.text = "#{@entity.winner} wins!"
        @label.align_centre
        @label.align_middle
      end
    end
  end

  def derender
    super
    @label&.remove
  end
end
