module Killable
  attr_reader :max_health, :health, :dead

  def initialize_killable(max_health:, health: max_health)
    @max_health = max_health
    @health = health
    @dead = false
  end

  def dead?
    !!@dead
  end

  def alive?
    !@dead
  end

  def kill
    @health = 0
    @dead = true
    @presenter&.derender
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
    kill if @health.zero?
  end
end
