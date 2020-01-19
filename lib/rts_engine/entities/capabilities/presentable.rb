module Presentable
  attr_reader :renderer, :presenter, :prerendered

  def initialize_presentable(renderer)
    @renderer = renderer
    @presenter = renderer.present(self)
    @prerendered = false
  end

  def present
    unless @prerendered
      @presenter&.prerender
      @prerendered = true
    end
    @presenter&.render
  end
end
