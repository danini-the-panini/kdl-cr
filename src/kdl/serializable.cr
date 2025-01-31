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

        {% for ivar in @type.instance_vars %}
          {% if ann = ivar.annotation(::KDL::Argument) %}
            {% unless ann[:ignore] || ann[:ignore_deserialize] %}
              {%
                argument_annos << {
                  id:          ivar.id,
                  has_default: ivar.has_default_value?,
                  default:     ivar.default_value,
                  nilable:     ivar.type.nilable?,
                  type:        ivar.type,
                  converter:   ann[:converter],
                  presence:    ann[:presence]
                }
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
            %}
          {% end %}
        {% end %}

        {% for value, index in argument_annos %}
          %var{value[:id]} = node[{{index}}]
          %found{value[:id]} = true
        {% end %}
        {% if arguments_anno %}
          %var{arguments_anno[:id]} = node.arguments[{{argument_annos.size}}..].map(&.value)
          %found{arguments_anno[:id]} = true
        {% end %}
        found_props = [] of String
        {% for name, value in property_annos %}
          %var{name} = node[{{name.stringify}}]
          %found{name} = true
          found_props << {{name.stringify}}
        {% end %}
        {% if properties_anno %}
          %var{properties_anno[:id]} = node.properties.reject(found_props)
          %found{properties_anno[:id]} = true
        {% end %}
        {% for name, value in child_annos %}
          {% if value[:unwrap] == "argument" %}
            %var{name} = node.arg({{name.stringify}})
          {% elsif value[:unwrap] == "arguments" %}
            %var{name} = node.args({{name.stringify}})
          {% elsif value[:unwrap] == "properties" %}
            %var{name} = node.child({{name.stringify}}).properties.transform_values { |v, _| v.value }
          {% else %}
            %var{name} = {{value[:type]}}.from_kdl(node.child({{name.stringify}}))
          {% end %}
          %found{name} = true
        {% end %}
        {% for name, value in children_annos %}
          %var{name} = node.children.select { |n| n.name == {{name.stringify}} }.map { |n| {{value[:type]}}.from_kdl(n) }
          %found{name} = true
        {% end %}
      {% end %}
    end
  end
end

def Object.from_kdl(doc)
  new doc
end
