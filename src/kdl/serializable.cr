module KDL
  annotation Argument; end
  annotation Arguments; end
  annotation Property; end
  annotation Properties; end
  annotation Child; end
  annotation Children; end

  module Serializable
    class Error < Exception
      getter klass : String
      getter attribute : String?

      def initialize(message : String?, @klass : String, @attribute : String?)
        message = String.build do |io|
          io << message
          io << "\n  parsing "
          io << klass
          if attribute = @attribute
            io << '#' << attribute
          end
        end
        super(message)
      end
    end

    macro convert(expr, type)
      {% type_str = type.stringify %}
      {% if type_str == "Int8" %}
        {{expr}}.as(Number).to_i8
      {% elsif type_str == "Int16" %}
        {{expr}}.as(Number).to_i16
      {% elsif type_str == "Int32" %}
        {{expr}}.as(Number).to_i32
      {% elsif type_str == "Int64" %}
        {{expr}}.as(Number).to_i64
      {% elsif type_str == "Int128" %}
        {{expr}}.as(Number).to_i128
      {% elsif type_str == "UInt8" %}
        {{expr}}.as(Number).to_u8
      {% elsif type_str == "UInt16" %}
        {{expr}}.as(Number).to_u16
      {% elsif type_str == "UInt32" %}
        {{expr}}.as(Number).to_u32
      {% elsif type_str == "UInt64" %}
        {{expr}}.as(Number).to_u64
      {% elsif type_str == "UInt128" %}
        {{expr}}.as(Number).to_u128
      {% elsif type_str == "Float32" %}
        {{expr}}.as(Number).to_f32
      {% elsif type_str == "Float64" %}
        {{expr}}.as(Number).to_f64
      {% else %}
        {{expr}}.as({{type}})
      {% end %}
    end
  
    macro included
      def self.new(node : ::KDL::Node)
        new_from_kdl_node(node)
      end

      def self.new(doc : ::KDL::Document)
        new_from_kdl_node(::KDL::Node.new("__root", children: doc))
      end

      private def self.new_from_kdl_node(node : ::KDL::Node)
        instance = allocate
        instance.initialize(__node_for_kdl_serializable: node)
        ::GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end

      macro inherited
        def self.new(doc : ::KDL::Document)
          new_from_kdl_document(doc)
        end
      end
    end

    def initialize(*, __node_for_kdl_serializable node : ::KDL::Node)
      {% begin %}
        {% argument_annos   = [] of Nil %}
        {% arguments_anno   = nil %}
        {% property_annos   = {} of Nil => Nil %}
        {% properties_anno  = nil %}
        {% child_annos      = {} of Nil => Nil %}
        {% children_annos   = {} of Nil => Nil %}
        {% other_properties = {} of Nil => Nil %}

        {% all_properties = {} of Nil => Nil %}

        {% for ivar in @type.instance_vars %}
          {% if ann = ivar.annotation(::KDL::Argument) %}
            {% unless ann[:ignore] || ann[:ignore_deserialize] %}
              {%
                prop = {
                  id:          ivar.id,
                  has_default: ivar.has_default_value?,
                  default:     ivar.default_value,
                  nilable:     ivar.type.nilable?,
                  type:        ivar.type,
                  converter:   ann[:converter],
                  presence:    ann[:presence]
                }
                argument_annos << prop
                all_properties[ivar.id] = prop
              %}
            {% end %}
          {% elsif ann = ivar.annotation(::KDL::Arguments) %}
            {% unless ann[:ignore] || ann[:ignore_deserialize] %}
              {%
                arguments_anno = {
                  id:          ivar.id,
                  has_default: ivar.has_default_value?,
                  default:     ivar.default_value,
                  nilable:     ivar.type.nilable?,
                  type:        ivar.type,
                  converter:   ann[:converter],
                  presence:    ann[:presence]
                }
                all_properties[ivar.id] = arguments_anno
              %}
            {% end %}
          {% elsif ann = ivar.annotation(::KDL::Property) %}
            {% unless ann[:ignore] || ann[:ignore_deserialize] %}
              {%
                property_annos[ivar.id] = {
                  name:        (ann[:name] || ivar).id.stringify,
                  has_default: ivar.has_default_value?,
                  default:     ivar.default_value,
                  nilable:     ivar.type.nilable?,
                  type:        ivar.type,
                  converter:   ann[:converter],
                  presence:    ann[:presence]
                }
                all_properties[ivar.id] = property_annos[ivar.id]
              %}
            {% end %}
          {% elsif ann = ivar.annotation(::KDL::Properties) %}
            {% unless ann[:ignore] || ann[:ignore_deserialize] %}
              {%
                properties_anno = {
                  id:          ivar.id,
                  has_default: ivar.has_default_value?,
                  default:     ivar.default_value,
                  nilable:     ivar.type.nilable?,
                  type:        ivar.type,
                  converter:   ann[:converter],
                  presence:    ann[:presence]
                }
                all_properties[ivar.id] = properties_anno
              %}
            {% end %}
          {% elsif ann = ivar.annotation(::KDL::Child) %}
            {% unless ann[:ignore] || ann[:ignore_deserialize] %}
              {%
                child_annos[ivar.id] = {
                  name:        (ann[:name] || ivar).id.stringify,
                  has_default: ivar.has_default_value?,
                  default:     ivar.default_value,
                  nilable:     ivar.type.nilable?,
                  type:        ivar.type,
                  converter:   ann[:converter],
                  presence:    ann[:presence],
                  unwrap:      ann[:unwrap]
                }
                all_properties[ivar.id] = child_annos[ivar.id]
              %}
            {% end %}
          {% elsif ann = ivar.annotation(::KDL::Children) %}
            {% unless ann[:ignore] || ann[:ignore_deserialize] %}
              {%
                children_annos[ivar.id] = {
                  name:        (ann[:name] || ivar).id.stringify,
                  has_default: ivar.has_default_value?,
                  default:     ivar.default_value,
                  nilable:     ivar.type.nilable?,
                  type:        ivar.type,
                  converter:   ann[:converter],
                  presence:    ann[:presence]
                }
                all_properties[ivar.id] = children_annos[ivar.id]
              %}
            {% end %}
          {% else %}
            {%
              other_children[ivar.id] = {
                key:         ivar.id.stringify,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                type:        ivar.type
              }
              all_properties[ivar.id] = other_children[ivar.id]
            %}
          {% end %}
        {% end %}

        {% for value, index in argument_annos %}
          # argument
          %var{value[:id]} = convert(node[{{index}}], {{ value[:type] }})
          %found{value[:id]} = true
        {% end %}
        {% if arguments_anno %}
          # arguments
          %var{arguments_anno[:id]} = node.arguments[{{argument_annos.size}}..].map { |v| convert(v.value, {{ arguments_anno[:type].type_vars[0] }}) }
          %found{arguments_anno[:id]} = true
        {% end %}
        __found_props = [] of String
        {% for name, value in property_annos %}
          # property
          %var{name} = convert(node[{{value[:name]}}], {{ value[:type] }})
          %found{name} = true
          __found_props << {{value[:name]}}
        {% end %}
        {% if properties_anno %}
          # properties
          %var{properties_anno[:id]} = node.properties.reject(__found_props).transform_values { |v, _| convert(v.value,{{ properties_anno[:type].type_vars[0] }}) }
          %found{properties_anno[:id]} = true
        {% end %}
        {% for name, value in child_annos %}
          # child
          {% if value[:unwrap] == "argument" %}
            %var{name} = convert(node.arg({{name.stringify}}), {{ value[:type] }})
          {% elsif value[:unwrap] == "arguments" %}
            %var{name} = node.args({{name.stringify}}).map { |v| convert(v, {{ value[:type].type_vars[0] }}) }
          {% elsif value[:unwrap] == "properties" %}
            %var{name} = node.child({{name.stringify}}).properties.transform_values { |v, _| convert(v.value, {{ value[:type].type_vars[1] }}) }
          {% else %}
            %var{name} = {{value[:type]}}.from_kdl(node.child({{name.stringify}}))
          {% end %}
          %found{name} = true
        {% end %}
        {% for name, value in children_annos %}
          # children
          %var{name} = node.children.select { |n| n.name == {{value[:name]}} }.map { |n| {{value[:type].type_vars[0]}}.from_kdl(n) }
          %found{name} = true
        {% end %}

        {% for name, value in all_properties %}
          if %found{name}
            @{{name}} = %var{name}
          else
            {% unless value[:has_default] || value[:nilable] %}
              raise ::KDL::Serializable::Error.new("Missing KDL entry: {{value[:key].id}}", self.class.to_s, "{{ name }}")
            {% end %}
          end

          {% if value[:presence] %}
            @{{name}}_present = %found{name}
          {% end %}
        {% end %}
      {% end %}
    end

    def to_kdl(node_name : String = self.class.to_s, builder : ::KDL::Builder = ::KDL::Builder.new)
      {% begin %}
        builder.node(node_name) do
          {% for ivar in @type.instance_vars %}
            {% name = ivar.id %}
            {% if ann = ivar.annotation(::KDL::Argument) %}
              builder.arg(@{{name}})
            {% elsif ann = ivar.annotation(::KDL::Arguments) %}
              @{{name}}.each do |arg|
                builder.arg(arg)
              end
            {% elsif ann = ivar.annotation(::KDL::Property) %}
              builder.prop({{(ann[:name] || ivar).id.stringify}}, @{{name}})
            {% elsif ann = ivar.annotation(::KDL::Properties) %}
              @{{name}}.each do |key, value|
                builder.prop(key, value)
              end
            {% elsif ann = ivar.annotation(::KDL::Child) %}
              {% if ann[:unwrap] == "argument" %}
                builder.node({{(ann[:name] || ivar).id.stringify}}, @{{name}})
              {% elsif ann[:unwrap] == "arguments" %}
                builder.node({{(ann[:name] || ivar).id.stringify}}) do
                  @{{name}}.each do |arg|
                    builder.arg(arg)
                  end
                end
              {% elsif ann[:unwrap] == "properties" %}
                builder.node({{(ann[:name] || ivar).id.stringify}}, @{{name}})
              {% else %}
                @{{name}}.to_kdl({{(ann[:name] || ivar).id.stringify}}, builder)
              {% end %}
            {% elsif ann = ivar.annotation(::KDL::Children) %}
              @{{name}}.each do |value|
                value.to_kdl({{(ann[:name] || ivar).id.stringify}}, builder)
              end
            {% end %}
          {% end %}
        end
      {% end %}
    end
  end
end

def Object.from_kdl(doc)
  new doc
end

def Array.from_kdl(node : ::KDL::Node)
  node.arguments.map do |arg|
    arg.value
  end
end
