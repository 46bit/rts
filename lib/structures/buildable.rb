require_relative './destroyable'

class BuildableStructure < DestroyableStructure
  attr_reader :built

  def initialize(*args, built: false, **kargs)
    super(*args, **kargs, health: built ? self.class::MAX_HEALTH : 0)
    @built = built
  end

  def heal(*)
    super
    @built ||= @health == self.class::MAX_HEALTH
  end
end
