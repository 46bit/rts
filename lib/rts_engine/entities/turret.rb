require_relative "../../utils"
require_relative "./types/structure"
require_relative "./types/projectile"

class Turret < Structure
  FIRING_RATE = 5

  attr_reader :update_counter

  def initialize(renderer, position, player, built: true)
    super(renderer, position, player, max_health: 60, built: built, health: built ? 60 : 0, collision_radius: 5)
    @update_counter = 0
  end

  def update
    return if @dead || !@built

    @update_counter += 1
    if @update_counter >= self.class::FIRING_RATE
      projectile_angle = angle_to_nearest_enemy(@player.enemy_units)
      unless projectile_angle.nil?
        @update_counter = 0
        @player.projectiles << TurretProjectile.new(@renderer, @position, projectile_angle, @player)
      end
    end
  end

protected

  def angle_to_nearest_enemy(enemies)
    vector_to_nearest_enemy =
      enemies
        .map { |v| v.position - @position }
        .reject { |d| d.magnitude >= TurretProjectile::RANGE }
        .min_by(&:magnitude)

    unless vector_to_nearest_enemy.nil?
      Math.atan2(vector_to_nearest_enemy[0], vector_to_nearest_enemy[1])
    end
  end
end

class TurretProjectile < Projectile
  RANGE = 180
  DAMAGE = 10

  def initialize(renderer, position, direction, player)
    super(renderer, position, 3.5, direction, RANGE, DAMAGE, player, collision_radius: 4)
  end
end
