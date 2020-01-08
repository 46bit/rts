module Ownable
  attr_reader :player

  def initialize_ownable(player: nil)
    @player = player
  end

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
