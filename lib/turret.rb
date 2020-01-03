require 'matrix'
require_relative './projectile'
require_relative './utils'

class Turret < Vehicle
  UPDATES_PER_FIRING = 80

  attr_reader :deployed

  def initialize(*)
    super

    @deployed = false
  end

  def deploy
    return if @deployed
    @deployed = true
    @line.opacity = 0.0 # Create some easy visual difference
    @update_counter = 0
    @velocity = 0.0
    @angular_velocity = 0.0
  end

  def update(accelerate_mode)
    return super(accelerate_mode) unless @deployed

    enemy_vehicles = accelerate_mode # FIXME: This repurposing of the argument is terrifying
    @update_counter += 1
    if @update_counter >= UPDATES_PER_FIRING
      projectile_angle = angle_to_nearest_enemy_vehicle(enemy_vehicles)
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

protected

  def angle_to_nearest_enemy_vehicle(enemy_vehicles)
    vector_to_nearest_enemy_vehicle =
      enemy_vehicles
        .map { |v| v.position - @position }
        .reject { |d| d.magnitude >= Projectile::MAXIMUM_RANGE }
        .min_by { |d| d.magnitude }

    unless vector_to_nearest_enemy_vehicle.nil?
      return Math.atan2(vector_to_nearest_enemy_vehicle[0], vector_to_nearest_enemy_vehicle[1])
    end
  end
end
