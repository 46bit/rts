require_relative "./camera"
require_relative "./shapes/shapes"
require_relative "./presenters/game"
require_relative "./presenters/player"
require_relative "./presenters/power_source"
require_relative "./presenters/factory"
require_relative "./presenters/turret"
require_relative "./presenters/commander"
require_relative "./presenters/bot"
require_relative "./presenters/tank"

class Renderer
  attr_reader :screen_size, :world_size, :scale_multiplier, :shapes
  attr_accessor :centre_x, :centre_y, :zoom_multiplier

  def initialize(screen_size:, world_size:)
    @screen_size = screen_size
    @world_size = world_size
    @centre_x = 0
    @centre_y = 0
    @zoom_multiplier = 1.0
    recalculate_scale_multiplier
  end

  def present(entity)
    case entity
    when Game
      GamePresenter.new(self, entity)
    when Player
      PlayerPresenter.new(self, entity)
    when PowerSource
      PowerSourcePresenter.new(self, entity)
    when Factory
      FactoryPresenter.new(self, entity)
    when Turret
      TurretPresenter.new(self, entity)
    when TurretProjectile
      TurretProjectilePresenter.new(self, entity)
    when Commander
      CommanderPresenter.new(self, entity)
    when Bot
      BotPresenter.new(self, entity)
    when Tank
      TankPresenter.new(self, entity)
    else
      raise "unknown class to present: #{entity.class}"
    end
  end

  def circle(**kargs)
    RenderCircle.new(self, **kargs)
  end

  def triangle(**kargs)
    RenderTriangle.new(self, **kargs)
  end

  def square(**kargs)
    RenderSquare.new(self, **kargs)
  end

  def quad(**kargs)
    RenderQuad.new(self, **kargs)
  end

  def line(**kargs)
    RenderLine.new(self, **kargs)
  end

  def text(text, **kargs)
    RenderText.new(self, text, **kargs)
  end

  def star(**kargs)
    RenderStar.new(self, **kargs)
  end

  def teardrop(**kargs)
    RenderTeardrop.new(self, **kargs)
  end

  def icon(**kargs)
    RenderIcon.new(self, **kargs)
  end

  def apply(type, value)
    case type
    when :static
      value
    when :distance
      value * @scale_multiplier
    when :x
      (value - @centre_x) * @scale_multiplier
    when :y
      (value - @centre_y) * @scale_multiplier
    else
      raise "unknown value type to render: #{type}"
    end
  end

  def unapply(type, value)
    case type
    when :static
      value
    when :distance
      value / @scale_multiplier
    when :x
      value / @scale_multiplier + @centre_x
    when :y
      value / @scale_multiplier + @centre_y
    else
      raise "unknown value type to render: #{type}"
    end
  end

  def recalculate_scale_multiplier
    @scale_multiplier = @screen_size.to_f / @world_size * @zoom_multiplier
  end

  def recompute_shapes
    Window.object_owners.each do |object_owner|
      next unless object_owner.respond_to?(:recompute)

      object_owner.recompute(invoke_parents: true)
    end
  end
end

class Window
  def self.object_owners
    @@window.instance_variable_get(:@objects).map { |object| object.instance_variable_get(:@owner) }.compact
  end
end
