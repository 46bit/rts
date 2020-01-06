module Killable
  attr_reader :health, :dead

  def dead?
    !!@dead
  end

  def kill
    @health = 0
    @dead = true
  end

  def damaged?
    @health < @max_health
  end

  def healthyness
    @health.to_f / @max_health
  end

  def repair(health_amount)
    @health = [@health + health_amount, @max_health].min
  end

  def damage(damage_amount)
    @health = [@health - damage_amount, 0].max
    kill if @health == 0
  end
end
