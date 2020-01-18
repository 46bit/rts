class Ruby2DShape
  def initialize(renderer, *args, parent: nil, **kargs)
    @parent = parent
    @shape_values = {}
    shape_attributes = self.class.shape_attributes
    kargs.each do |name, value|
      attr_type = shape_attributes[name]
      unless attr_type.nil?
        @shape_values[attr_type] ||= {}
        @shape_values[attr_type][name] = value
        value = renderer.apply(attr_type, value) unless attr_type == :static
        kargs[name] = value
      end
    end
    @shape = self.class::SHAPE.new(*args, **kargs)
    @shape.instance_variable_set(:@owner, self)
    @renderer = renderer
  end

  def recompute(invoke_parents: false)
    return @parent.recompute if invoke_parents && @parent

    @shape_values.each do |attr_type, attrs|
      next if attr_type == :static

      attrs.each do |attr_name, attr_value|
        unless attr_value.nil?
          new_value = @renderer.apply(attr_type, attr_value) unless attr_type == :static
          @shape.public_send(attr_name.to_s + "=", new_value)
        end
      end
    end
  end

  def remove
    @shape.remove
  end

  def add
    @shape.add
    recompute
  end

  class << self
    def attr_shape_static(*attrs)
      self.shape_attr(:static, attrs)
    end

    def attr_shape_distance(*attrs)
      self.shape_attr(:distance, attrs)
    end

    def attr_shape_x(*attrs)
      self.shape_attr(:x, attrs)
    end

    def attr_shape_y(*attrs)
      self.shape_attr(:y, attrs)
    end

    def shape_attributes
      self.class_variable_get(:@@shape_attributes)
    end

  protected

    def shape_attr(attr_type, attr_names)
      self.record_shape_attrs(attr_type, attr_names)

      attr_names.each do |attr_name|
        define_method(attr_name.to_s) do
          @shape_values.dig(attr_type, attr_name)
        end

        define_method("#{attr_name}=") do |value|
          @shape_values[attr_type] ||= {}
          @shape_values[attr_type][attr_name] = value
          value = @renderer.apply(attr_type, value) unless attr_type == :static
          @shape.public_send("#{attr_name}=", value)
        end
      end
    end

    def record_shape_attrs(attr_type, attr_names)
      unless self.class_variable_defined?(:@@shape_attributes)
        self.class_variable_set(:@@shape_attributes, {})
      end

      shape_attributes = self.class_variable_get(:@@shape_attributes)
      attr_names.each do |attr_name|
        shape_attributes[attr_name] = attr_type
      end
    end
  end
end
