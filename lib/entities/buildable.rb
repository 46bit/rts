module Buildable
  attr_reader :built

  def built?
    @built
  end

  def under_construction?
    !@built
  end

  def repair(*)
    super
    @built ||= !damaged?
  end
end
