def vector_from_magnitude_and_direction(magnitude, direction)
  # Angles anticlockwise from south (?)
  x = magnitude * Math.sin(direction)
  y = magnitude * Math.cos(direction)
  Vector[x, y]
end

def magnitude_and_direction_from_vector(vector)
  # Angles anticlockwise from south (?)
  direction = Math.atan2(vector[0], vector[1])
  magnitude = vector.magnitude
  return magnitude, direction
end

def to_degrees(radians)
  radians / Math::PI * 180
end
