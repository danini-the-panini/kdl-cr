# This is an extremely simplified version, only differentiates between `Nil` and everything else.
def Union.from_kdl(node : KDL::Node)
  {% raise Exception.new "Please specify a more exact type." if (T.size > 2 || (T.size == 2 && !T.includes?(::Nil))) %}
  {% for type in T %}
    {% if type == Nil %}
    nil
    {% else %}
      {{type}}.from_kdl node
    {% end %}
  {% end %}
end
