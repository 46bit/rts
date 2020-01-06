module Ownable
  attr_reader :player

  def owner?(player)
    @player == player
  end

  def occupied?
    !@player.nil?
  end

  def capture(player)
    @player = player
  end
end
