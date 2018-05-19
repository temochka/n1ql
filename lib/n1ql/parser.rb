module N1ql
  class Parser < Parslet::Parser
    # Helpers
    def trimmed(atom)
      ws? >> atom >> ws?
    end

    # Keywords
    def keyword(str, as: nil)
      atom = str.chars.map! { |char| match["#{char.upcase}#{char.downcase}"] }.reduce(:>>)
      ws? >>
        (as ? atom.as(as) : atom) >>
        (ws.present? | keyword_friends.present? | any.absent?)
    end
    rule(:keyword_friends) { comma | rparen }

    # Whitespace
    rule(:ws) { match('\s').repeat(1).ignore }
    rule(:ws?) { ws.maybe }

    # Symbols
    rule(:star) { str('*') }
    rule(:backtick) { str('`') }
    rule(:colon) { trimmed(str(':')) }
    rule(:lparen) { str('(') >> ws? }
    rule(:rparen) { ws? >> str(')') }
    rule(:lbrack) { trimmed(str('[')) }
    rule(:rbrack) { trimmed(str(']')) }
    rule(:lbrace) { str('{') >> ws? }
    rule(:rbrace) { trimmed(str('}')) }
    rule(:comma) { trimmed(str(',')) }
    rule(:squote) { str("'") }
    rule(:dquote) { str('"') }

    # Operators

    # 1. Arithmetic
    rule(:op_plus) { str('+') }
    rule(:op_minus) { str('-') }
    rule(:op_mul) { str('*') }
    rule(:op_div) { str('/') }
    rule(:op_mod) { str('%') }

    # 2. Comparison
    rule(:op_eq) { str('=') }
    rule(:op_eqeq) { str('==') }
    rule(:op_is) { keyword('IS') }
    rule(:op_ltgt) { str('<>') }
    rule(:op_noteq) { str('!=') }
    rule(:op_lt) { str('<') }
    rule(:op_lte) { str('<=') }
    rule(:op_gt) { str('>') }
    rule(:op_gte) { str('>=') }
    rule(:op_like) { keyword('LIKE') }

    # 3. Strings
    rule(:op_concat) { str('||') }

    # 4. Logic
    rule(:op_or) { keyword('OR') }
    rule(:op_and) { keyword('AND') }
    rule(:op_not) { keyword('NOT') }

    # 5. Inclusion
    rule(:op_in) { keyword('IN') }
    rule(:op_within) { keyword('WITHIN') }

    # 6. Access
    rule(:op_dot) { trimmed(str('.')) }
    rule(:op_lookup) { lbrack >> trimmed(integer.as(:integer)).as(:index) >> rbrack }

    # 7. Complex Operators

    rule(:complex_operator) { op_array_pred | op_array }

    # 7.1 ANY, EVERY
    rule(:var_binding) do
      simple_name.as(:l) >> (keyword('IN') | keyword('WITHIN')) >> ws >> expression.as(:r)
    end
    rule(:var_bindings) do
      ((var_binding >> comma).repeat >> var_binding).repeat.as(:bindings)
    end

    rule(:op_array_pred) do
      (keyword('ANY', as: :opname) | keyword('EVERY', as: :opname)) >> ws >>
        var_bindings >>
        keyword('SATISFIES') >> ws >> expression.as(:predicate) >> keyword('END')
    end

    # 7.2 ARRAY
    rule(:op_array) do
      keyword('ARRAY', as: :opname) >> ws >>
        expression.as(:array_expression) >>
        keyword('FOR') >> ws >>
        var_bindings >>
        (keyword('WHEN') >> ws >> expression).maybe.as(:predicate) >>
        keyword('END')
    end

    # 7.3 CASE (simple)
    rule(:op_case) do
      keyword('CASE', as: :opname) >> ws >>
        expression.as(:simple_case) >>
          (keyword('WHEN') >> ws >> expression.as(:l) >>
            keyword('THEN') >> ws >> expression.as(:r)).repeat(1).as(:bindings) >>
          (keyword('ELSE') >> ws >> expression).maybe.as(:else) >>
          keyword('END')
    end

    # Type literals
    rule(:type_literal) { null | boolean | number | string | array | object }

    # 1. Boolean
    rule(:boolean) { (keyword('TRUE') | keyword('FALSE')).as(:boolean) }

    # 2. Numbers
    rule(:numeric) { match('[0-9]') }
    rule(:zero) { str('0') >> numeric.absent? }
    rule(:integer) { op_minus.maybe >> (match('[1-9]') >> numeric.repeat | zero) }
    rule(:float) { op_minus.maybe >> integer >> str('.') >> zero.repeat >> integer.maybe }
    rule(:number) { float.as(:float) | integer.as(:integer) }

    # 3. String values
    rule(:single_quoted_string) { squote >> ((str('\\').ignore >> squote) | squote.absent? >> any).repeat.as(:string) >> squote }
    rule(:double_quoted_string) { dquote >> ((str('\\').ignore >> dquote) | dquote.absent? >> any).repeat.as(:string) >> dquote }
    rule(:string) { single_quoted_string | double_quoted_string }

    # 4. Arrays
    rule(:array) { lbrack >> ((expression >> comma).repeat >> expression.maybe).as(:array) >> rbrack }

    # 5. Objects
    rule(:field) { expression.as(:field) >> colon >> expression.as(:value) }
    rule(:object) { lbrace >> ((field >> comma).repeat >> field.maybe).as(:object) >> rbrace }

    # 6. NULL
    rule(:null) { keyword('NULL', as: :null) }

    # Names
    rule(:escaped_name) { backtick.ignore >> (backtick.absent? >> any).repeat(1) >> backtick.ignore }
    rule(:unescaped_name) { match('[a-zA-Z_]') >> match('[\w_]').repeat }
    rule(:name) { (unescaped_name | escaped_name).as(:name)  }
    rule(:simple_name) { name >> op_dot.absent? }
    rule(:_path) { (name >> op_lookup.repeat(0, 1) | star.as(:name)) >> (op_dot >> _path).repeat }
    rule(:path) { _path.as(:path) }
    rule(:parameter) { (str('$').ignore >> _path).as(:parameter) }

    # Functions
    rule(:arguments) { (expression >> comma).repeat >> expression.repeat(1, 1) }
    rule(:function) { name.as(:function) >> lparen >> arguments.as(:arguments) >> rparen }

    # Expressions
    rule(:operand) { parameter | type_literal | complex_operator | function | path }

    # Parslet expects precedence while N1QL docs use order of operation.
    # Higher precedence means lower order of operation.
    PRECEDENCE_CAP = 20

    rule(:expression) do
      infix_expression(lparen >> expression >> rparen | (op_not >> ws >> operand).as(:op_not) | operand,
                       [trimmed(op_or),     PRECEDENCE_CAP - 16, :right],
                       [trimmed(op_and),    PRECEDENCE_CAP - 15, :right],
                       [trimmed(op_eq),     PRECEDENCE_CAP - 12, :right],
                       [trimmed(op_eqeq),   PRECEDENCE_CAP - 12, :right],
                       [trimmed(op_ltgt),   PRECEDENCE_CAP - 12, :right],
                       [trimmed(op_noteq),  PRECEDENCE_CAP - 12, :right],
                       [trimmed(op_lte),    PRECEDENCE_CAP - 11, :right],
                       [trimmed(op_lt),     PRECEDENCE_CAP - 11, :right],
                       [trimmed(op_gte),    PRECEDENCE_CAP - 11, :right],
                       [trimmed(op_gt),     PRECEDENCE_CAP - 11, :right],
                       [trimmed(op_like),   PRECEDENCE_CAP - 10, :right],
                       [trimmed(op_in),     PRECEDENCE_CAP - 8,  :right],
                       [trimmed(op_within), PRECEDENCE_CAP - 8,  :right],
                       [trimmed(op_concat), PRECEDENCE_CAP - 7,  :right],
                       [trimmed(op_is),     PRECEDENCE_CAP - 7,  :right],
                       [trimmed(op_minus),  PRECEDENCE_CAP - 6,  :right],
                       [trimmed(op_plus),   PRECEDENCE_CAP - 6,  :right],
                       [trimmed(op_mul),    PRECEDENCE_CAP - 5,  :right],
                       [trimmed(op_div),    PRECEDENCE_CAP - 5,  :right],
                       [trimmed(op_mod),    PRECEDENCE_CAP - 5,  :right])
    end

    # Columns (SELECT columns)
    rule(:column_alias) { keyword('AS') >> ws >> simple_name }
    rule(:column) { expression.as(:column) >> (ws >> column_alias).maybe.as(:as) }
    rule(:columns) do
      column >> (comma >> column).repeat
    end

    # Data sources (FROM data sources)
    rule(:data_source) do
      simple_name.as(:as) >> (ws >> keyword('ON') >> ws >> expression.as(:on)).maybe
    end

    rule(:data_sources) do
       data_source >> (ws >> keyword('JOIN') >> ws >> data_source).repeat
    end

    rule(:ordering_term) do
      expression.as(:order_expression) >> (ws >> (keyword('ASC') | keyword('DESC'))).maybe.as(:order_direction)
    end

    rule(:order_by) do
       ordering_term >>
        (comma >> ordering_term).repeat
    end

    # Grouping terms (GROUP BY grouping terms)
    rule(:group_by) { (expression >> comma).repeat >> expression }

    # SELECT query
    rule(:select) do
      keyword('SELECT') >> ws >>
        (keyword('DISTINCT') >> ws).maybe.as(:distinct) >>
        columns.as(:what) >>
        (ws >> keyword('FROM') >> ws >> data_sources).maybe.as(:from) >>
        (ws >> keyword('WHERE') >> ws >> expression).maybe.as(:where) >>
        (ws >> keyword('GROUP') >> ws >> keyword('BY') >> ws >> group_by).maybe.as(:group_by) >>
        (ws >> keyword('HAVING') >> ws >> expression).maybe.as(:having) >>
        (ws >> keyword('ORDER') >> ws >> keyword('BY') >> ws >> order_by).maybe.as(:order_by) >>
        (ws >> keyword('LIMIT') >> ws >> expression).maybe.as(:limit) >>
        (ws >> keyword('OFFSET') >> ws >> expression).maybe.as(:offset) >>
        ws?
    end

    root(:select)
  end
end
