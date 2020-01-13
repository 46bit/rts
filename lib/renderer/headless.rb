class Renderer
  attr_reader :world_size

  def initialize(_screen_size, world_size)
    @world_size = world_size
  end
end
