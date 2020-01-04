require_relative './buildable'
require_relative '../entities/projectile'
require_relative '../utils'

class Turret < BuildableStructure
  COLLISION_RADIUS = 5
  MAX_HEALTH = 40
  FIRING_RATE = 80

  attr_reader :update_counter, :circle

  def initialize(*)
    super
    @update_counter = 0

    prerender unless HEADLESS
  end

  def kill
    super
    unless HEADLESS
      @circle.remove
      @health_bar.remove
    end
  end

  def update(enemies)
    return if @dead || !@built

    @update_counter += 1
    if @update_counter >= self.class::FIRING_RATE
      projectile_angle = angle_to_nearest_enemy(enemies)
      unless projectile_angle.nil?
        @update_counter = 0
        return Projectile.new(
          @position,
          projectile_angle,
          @player.color,
          scale_factor: @scale_factor
        )
      end
    end
  end

  def prerender
    @circle = Circle.new(
      x: scale(@position[0] - 2.5),
      y: scale(@position[1] - 2.5),
      radius: scale(5),
      color: @player.color,
      opacity: @built ? 1.0 : (0.2 + healthyness * 0.8),
      segments: 20,
      z: 2,
    )
    @health_bar = Line.new(
      x1: scale(@position[0] - 7.5),
      y1: scale(@position[1] + 4.5),
      x2: scale(@position[0] + 2.5),
      y2: scale(@position[1] + 4.5),
      width: scale(1.5),
      color: @player.color,
      z: 2,
    )
    # @range_circle = Circle.new(
    #   x: scale(@position[0] - 1.5),
    #   y: scale(@position[1] - 1.5),
    #   radius: scale(Projectile::MAXIMUM_RANGE),
    #   color: @player.color,
    #   opacity: 0.1,
    #   z: 0,
    # )
  end

  def render
    @circle.opacity = @built ? 1.0 : (0.2 + healthyness * 0.8)

    @health_bar.x2 = scale(@position[0] - 7.5 + 10 * healthyness)
    @health_bar.width = healthyness > 0.5 ? scale(1.5) : scale(2)
    if damaged?
      @health_bar.add
    else
      @health_bar.remove
    end
  end

protected

  def angle_to_nearest_enemy(enemies)
    vector_to_nearest_enemy =
      enemies
        .map { |v| v.position - @position }
        .reject { |d| d.magnitude >= Projectile::MAXIMUM_RANGE }
        .min_by { |d| d.magnitude }

    unless vector_to_nearest_enemy.nil?
      return Math.atan2(vector_to_nearest_enemy[0], vector_to_nearest_enemy[1])
    end
  end
end
