require_relative './buildable'
require_relative '../entities/projectile'
require_relative '../utils'

class Turret < BuildableStructure
  COLLISION_RADIUS = 5
  MAX_HEALTH = 300
  FIRING_RATE = 5
  RADIUS = 5.0

  attr_reader :update_counter, :square, :diagonal_square, :health_bar

  def initialize(*)
    super
    @update_counter = 0

    prerender unless HEADLESS
  end

  def kill
    super
    unless HEADLESS
      @square.remove
      @diagonal_square.remove
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
          @renderer,
        )
      end
    end
  end

  def prerender
    @square = @renderer.square(
      x: @position[0] - RADIUS,
      y: @position[1] - RADIUS,
      size: RADIUS * 2,
      color: @player.color,
      opacity: @built ? 1.0 : (0.2 + healthyness * 0.8),
      z: 2,
    )
    distance_to_points = Math.sqrt(2) * RADIUS
    @diagonal_square = @renderer.quad(
      x1: @position[0],
      y1: @position[1] - distance_to_points,
      x2: @position[0] + distance_to_points,
      y2: @position[1],
      x3: @position[0],
      y3: @position[1] + distance_to_points,
      x4: @position[0] - distance_to_points,
      y4: @position[1],
      color: @player.color,
      opacity: @built ? 1.0 : (0.2 + healthyness * 0.8),
      z: 2,
    )
    @health_bar = @renderer.line(
      x1: @position[0] - RADIUS,
      y1: @position[1] + RADIUS + 1,
      x2: @position[0] + RADIUS,
      y2: @position[1] + RADIUS + 1,
      width: 1.5,
      color: @player.color,
      z: 2,
    )
    # @range_circle = @renderer.circle(
    #   x: @position[0] - RADIUS,
    #   y: @position[1] - RADIUS,
    #   radius: Projectile::MAXIMUM_RANGE,
    #   color: @player.color,
    #   opacity: 0.1,
    #   z: 0,
    # )
  end

  def render
    @square.opacity = @built ? 1.0 : (0.2 + healthyness * 0.8)
    @diagonal_square.opacity = @built ? 1.0 : (0.2 + healthyness * 0.8)

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
        .reject { |d| d.magnitude >= Projectile::MAXIMUM_RANGE }
        .min_by { |d| d.magnitude }

    unless vector_to_nearest_enemy.nil?
      return Math.atan2(vector_to_nearest_enemy[0], vector_to_nearest_enemy[1])
    end
  end
end
