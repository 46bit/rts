require_relative '../utils'
require_relative '../entities/structure'
require_relative '../entities/projectile'

class Turret < Structure
  FIRING_RATE = 5
  RADIUS = 5.0

  attr_reader :update_counter, :star, :health_bar

  def initialize(renderer, position, player, built: true)
    super(renderer, position, player, max_health: 60, built: built, health: built ? 300 : 0, collision_radius: 5)
    @update_counter = 0
    prerender unless HEADLESS
  end

  def kill
    super
    unless HEADLESS
      @star.remove if @star
      @health_bar.remove if @health_bar
    end
  end

  def update(enemies)
    return if @dead || !@built

    @update_counter += 1
    if @update_counter >= self.class::FIRING_RATE
      projectile_angle = angle_to_nearest_enemy(enemies)
      unless projectile_angle.nil?
        @update_counter = 0
        return TurretProjectile.new(
          @renderer,
          @position,
          projectile_angle,
          @player,
        )
      end
    end
  end

  def prerender
    @star ||= @renderer.star(
      x: @position[0],
      y: @position[1],
      radius: RADIUS,
      color: @player.color,
      opacity: @built ? 1.0 : (0.2 + healthyness * 0.8),
      z: 2,
    )
    @health_bar ||= @renderer.line(
      x1: @position[0] - RADIUS,
      y1: @position[1] + RADIUS + 3,
      x2: @position[0] + RADIUS,
      y2: @position[1] + RADIUS + 3,
      width: 1.5,
      color: @player.color,
      z: 2,
    )
    # @range_circle ||= @renderer.circle(
    #   x: @position[0] - RADIUS,
    #   y: @position[1] - RADIUS,
    #   radius: Projectile::MAXIMUM_RANGE,
    #   color: @player.color,
    #   opacity: 0.1,
    #   z: 0,
    # )
  end

  def render
    @star.opacity = @built ? 1.0 : (0.2 + healthyness * 0.8)

    @health_bar.x2 = @position[0] - RADIUS + 2 * RADIUS * healthyness
    @health_bar.width = healthyness > 0.5 ? 1.5 : 2
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
        .reject { |d| d.magnitude >= TurretProjectile::RANGE }
        .min_by { |d| d.magnitude }

    unless vector_to_nearest_enemy.nil?
      return Math.atan2(vector_to_nearest_enemy[0], vector_to_nearest_enemy[1])
    end
  end
end

class TurretProjectile < Projectile
  RANGE = 180
  DAMAGE = 10

  def initialize(renderer, position, direction, player)
    super(renderer, position, 3.5, direction, RANGE, DAMAGE, 6, 6, player, opacity: 0.7, collision_radius: 4)
  end
end
