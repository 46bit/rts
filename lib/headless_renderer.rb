class HeadlessRenderer
  attr_reader :world_size

  def initialize(world_size:)
    @world_size = world_size
  end

  def present(_entity, **_kargs); end
end
