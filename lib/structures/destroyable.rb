require_relative './structure'

class DestroyableStructure < Structure
  MAX_HEALTH = 100
  HEALINGS = {
    vehicle_repair: 20,
  }
  DAMAGES = {
    vehicle_collision: 10,
    projectile_collision: 5,
  }

  attr_reader :health, :dead

  def initialize(*args, health: self.class::MAX_HEALTH, **kargs)
    super(*args, **kargs)
    @health = health
    @dead = false
  end

  def dead?
    @dead
  end

  def damaged?
    @health < self.class::MAX_HEALTH
  end

  def healthyness
    @health.to_f / self.class::MAX_HEALTH
  end

  def heal(cause)
    heal_amount = self.class::HEALINGS[cause]
    raise "healing #{cause} not found" if heal_amount.nil?
    @health = [@health + heal_amount, self.class::MAX_HEALTH].min
  end

  def damage(cause)
    damage_amount = self.class::DAMAGES[cause]
    raise "damage #{cause} not found" if damage_amount.nil?
    @health = [@health - damage_amount, 0].max
    kill if @health == 0
  end

  def kill
    @dead = true
  end
end
