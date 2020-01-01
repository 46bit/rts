class Generator
  attr_reader :position, :capacity
  attr_reader :player_owner

  def initialize(position, capacity: 1.0)
    @position = position
    @capacity = capacity
    @player_owner = nil
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

  def tick
  end
end
