class Generator
  attr_reader :position, :capacity
  attr_reader :player_owner, :triangle, :target_circle

  def initialize(position, capacity: 1.0, scale_factor: 1.0)
    @position = position
    @capacity = capacity
    @player_owner = nil

    @triangle = Triangle.new(
      x1: @position[0] * scale_factor,
      y1: (@position[1] - 6.5) * scale_factor,
      x2: (@position[0] + 6.5) * scale_factor,
      y2: (@position[1] + 6.5) * scale_factor,
      x3: (@position[0] - 6.5) * scale_factor,
      y3: (@position[1] + 6.5) * scale_factor,
      color: 'white',
      z: 1,
    )
    @target_circle = Circle.new(
      x: @position[0] * scale_factor,
      y: @position[1] * scale_factor,
      radius: scale_factor * 9,
      opacity: 0,
      z: 0,
    )
  end

  def capture(player)
    puts "generator '#{self.object_id}' captured by player with color: #{player.color}"
    @player_owner = player
  end

  def occupied?
    !@player_owner.nil?
  end

  def owner?(player)
    @player_owner == player
  end

  def contains?(x, y)
    @target_circle.contains?(x, y)
  end

  def tick
    @triangle.color = occupied? ? @player_owner.color : 'white'
  end
end
