module N1ql
  class Precompiler < Parslet::Transform
    rule(null: simple(:_)) { nil }
    rule(boolean: /\Atrue\Z/i) { true }
    rule(boolean: /\Afalse\Z/i) { false }
    rule(integer: simple(:int)) { Integer(int) }
    rule(float: simple(:float)) { Float(float) }
    rule(string: simple(:string)) { string }
    rule(array: sequence(:array)) { Ast::Node.new(['[]', *array]) }
    rule(field: subtree(:field), value: subtree(:value)) { [field, value] }
    rule(object: subtree(:fields)) { Ast::Node.new(fields.to_h) }
    rule(function: simple(:name), arguments: sequence(:arguments)) { Ast::Node.new(["#{name}()", *arguments]) }
    rule(function: simple(:name), arguments: simple(:argument)) { Ast::Node.new(["#{name}()", argument]) }

    rule(o: simple(:o), l: subtree(:l), r: subtree(:r)) { Ast::Node.new([o, l, r]) }

    rule(name: simple(:name)) { Ast::Name.new(name) }
    rule(index: simple(:index)) { Ast::Lookup.new(index) }
    rule(path: sequence(:names)) { Ast::Path.new(names) }
    rule(path: simple(:name)) { Ast::Path.new([name]) }
    rule(parameter: sequence(:names)) { Ast::Path.new(names, '$') }
    rule(parameter: simple(:name)) { Ast::Path.new([name], '$') }

    rule(as: simple(:as)) { Ast::Node.new(as: as) }
    rule(as: simple(:as), on: simple(:on)) { Ast::Node.new(as: as, on: on) }

    rule(column: subtree(:name), as: simple(:as)) do
      Ast::Column.new(name, as)
    end

    rule(l: simple(:l), r: simple(:r)) { [l, r] }

    rule(op_not: subtree(:expression)) { Ast::Node.new(['NOT', expression]) }

    # ANY, EVERY
    rule(opname: simple(:pred),
         bindings: subtree(:pred_bindings),
         predicate: subtree(:predicate)) do
      Ast::Node.new([pred, *pred_bindings.flatten(1), predicate])
    end

    # ARRAY
    rule(opname: simple(:opname),
         array_expression: simple(:expression),
         bindings: subtree(:pred_bindings),
         predicate: subtree(:predicate)) do
      if predicate
        Ast::Node.new([opname, expression, *pred_bindings.flatten(1), predicate])
      else
        Ast::Node.new([opname, expression, *pred_bindings.flatten(1)])
      end
    end

    rule(order_expression: subtree(:expression),
         order_direction: simple(:order)) do
      Ast::Node.new(order == 'DESC' ? ['DESC', expression] : expression)
    end

    rule(what: subtree(:what),
         distinct: simple(:distinct),
         from: subtree(:from),
         where: subtree(:where),
         group_by: subtree(:group_by),
         having: subtree(:having),
         order_by: subtree(:order_by),
         limit: simple(:limit),
         offset: simple(:offset)) do
      Ast::Node.new({ WHAT: what && (what.is_a?(Array) ? what : [what]),
                      DISTINCT: (true if distinct),
                      FROM: from && (from.is_a?(Array) ? from : [from]),
                      WHERE: where,
                      GROUP_BY: group_by && (group_by.is_a?(Array) ? group_by : [group_by]),
                      HAVING: having,
                      ORDER_BY: order_by && (order_by.is_a?(Array) ? order_by : [order_by]),
                      LIMIT: limit,
                      OFFSET: offset }.compact)
    end
  end
end
