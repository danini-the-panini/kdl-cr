module KDL
  annotation Argument; end
  annotation Arguments; end
  annotation Property; end
  annotation Properties; end
  annotation Child; end
  annotation Children; end

  module Serializable
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
                  key:         (ann[:key] || ivar).id.stringify,
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
                  key:         (ann[:key] || ivar).id.stringify,
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
                  key:         (ann[:key] || ivar).id.stringify,
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
          %var{value[:id]} = node[{{index}}].as({{ value[:type] }})
          %found{value[:id]} = true
        {% end %}
        {% if arguments_anno %}
          # arguments
          %var{arguments_anno[:id]} = node.arguments[{{argument_annos.size}}..].map(&.value).as({{ arguments_anno[:type] }})
          %found{arguments_anno[:id]} = true
        {% end %}
        __found_props = [] of String
        {% for name, value in property_annos %}
          # property
          %var{name} = node[{{name.stringify}}].as({{ value[:type] }})
          %found{name} = true
          __found_props << {{name.stringify}}
        {% end %}
        {% if properties_anno %}
          # properties
          %var{properties_anno[:id]} = node.properties.reject(__found_props).as({{ properties_anno[:type] }})
          %found{properties_anno[:id]} = true
        {% end %}
        {% for name, value in child_annos %}
          # child
          {% if value[:unwrap] == "argument" %}
            %var{name} = node.arg({{name.stringify}}).as({{ value[:type] }})
          {% elsif value[:unwrap] == "arguments" %}
            %var{name} = node.args({{name.stringify}}).as({{ value[:type] }})
          {% elsif value[:unwrap] == "properties" %}
            %var{name} = node.child({{name.stringify}}).properties.transform_values { |v, _| v.value }.as({{ value[:type] }})
          {% else %}
            %var{name} = {{value[:type]}}.from_kdl(node.child({{name.stringify}}))
          {% end %}
          %found{name} = true
        {% end %}
        {% for name, value in children_annos %}
          # children
          %var{name} = node.children.select { |n| n.name == {{name.stringify}} }.map { |n| {{value[:type]}}.from_kdl(n) }.as({{ value[:type] }})
          %found{name} = true
        {% end %}

        {% for name, value in all_properties %}
          if %found{name}
            @{{name}} = %var{name}
          else
            {% unless value[:has_default] || value[:nilable] %}
              raise ::KDL::SerializableError.new("Missing KDL entry: {{value[:key].id}}", self.class.to_s)
            {% end %}
          end

          {% if value[:presence] %}
            @{{name}}_present = %found{name}
          {% end %}
        {% end %}
        {% debug %}
      {% end %}
    end
  end
end

def Object.from_kdl(doc)
  new doc
end
