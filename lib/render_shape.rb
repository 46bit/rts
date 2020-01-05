require 'set'

class RenderShape
  def self.attr_shape_static(*attr_names)
    attr_names.each do |attr_name|
      self.define_method("#{attr_name}") do
        @shape.public_send(attr_name)
      end

      self.define_method("#{attr_name}=") do |value|
        @shape.public_send("#{attr_name}=", value)
      end
    end
  end

  def self.record_shape_attrs(attr_type, attr_names)
    unless self.class_variable_defined?(:@@shape_attributes)
      self.class_variable_set(:@@shape_attributes, {})
    end

    shape_attributes = self.class_variable_get(:@@shape_attributes)
    attr_names.each do |attr_name|
      shape_attributes[attr_name] = attr_type
    end
  end

  def self.shape_attr(attr_type, attr_names)
    self.record_shape_attrs(attr_type, attr_names)

    attr_names.each do |attr_name|
      define_method("#{attr_name}") do
        @shape_values.dig(attr_type, attr_name)
      end

      define_method("#{attr_name}=") do |value|
        @shape_values[attr_type] ||= {}
        @shape_values[attr_type][attr_name] = value
        @shape.public_send("#{attr_name}=", @renderer.apply(attr_type, value))
      end
    end
  end

  def self.attr_shape_distance(*attrs)
    self.shape_attr(:distance, attrs)
  end

  def self.attr_shape_x(*attrs)
    self.shape_attr(:x, attrs)
  end

  def self.attr_shape_y(*attrs)
    self.shape_attr(:y, attrs)
  end

  def self.shape_attributes
    self.class_variable_get(:@@shape_attributes)
  end

  def initialize(renderer, *args, **kargs)
    @shape_values = {}
    shape_attributes = self.class.shape_attributes
    kargs.each do |name, value|
      attr_type = shape_attributes[name]
      unless attr_type.nil?
        @shape_values[attr_type] ||= {}
        @shape_values[attr_type][name] = value
        kargs[name] = renderer.apply(attr_type, value)
      end
    end
    @shape = self.class::SHAPE.new(*args, **kargs)
    @renderer = renderer
    @renderer.attach(self)
  end

  def recompute
    self.class.shape_attributes.each do |attr_name, attr_type|
      value = @shape_values[attr_type][attr_name]
      unless value.nil?
        new_value = @renderer.apply(attr_type, value)
        @shape.public_send(attr_name.to_s + "=", new_value)
      end
    end
  end

  def remove
    @shape.remove
    @renderer.detach(self)
  end

  def add
    @shape.add
    @renderer.attach(self)
    recompute
  end
end
