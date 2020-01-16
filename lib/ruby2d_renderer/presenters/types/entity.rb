class EntityPresenter
  attr_reader :renderer, :entity

  def initialize(renderer, entity)
    @renderer = renderer
    @entity = entity
  end

  def prerender; end

  def render; end

  def derender; end
end
