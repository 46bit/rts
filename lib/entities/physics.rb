Physics = Struct.new(
  :mass,
  :power,
  :friction_coefficient,
  :drag_coefficient,
  :drag_area,
  :air_mass_density,
  :rolling_resistance_coefficient,
  # This one isn't well-founded at all. We might want to model dynamics–angular momentum.
  :turn_coefficient,
) do
  def normal_force
    mass * 9.81
  end

  def grip
    normal_force * friction_coefficient
  end

  def momentum(velocity)
    mass * velocity
  end

  def air_resistance(velocity)
    0.5 * air_mass_density * (velocity**2) * drag_coefficient * drag_area
  end

  def rolling_resistance
    rolling_resistance_coefficient * normal_force
  end

  def rolling_resistance_forces(velocity, angular_velocity)
    per_unit = rolling_resistance.to_f / (velocity.abs + angular_velocity.abs)
    return Vector[0, 0] if per_unit.infinite?
    return Vector[
      velocity * per_unit,
      angular_velocity * per_unit,
    ]
  end

  def max_acceleration_force
    [power, grip].min
  end

  def turning_angle
    Math::PI / turn_coefficient
  end
end

DEFAULT_PHYSICS = Physics.new(
  1.0,
  5.0,
  1.0,
  0.03,
  1.0,
  # Air mass density seems to be closer to 1.2, but that gave severe results…
  0.5,
  0.1,
  2500.0, # 3500.0,
).freeze
