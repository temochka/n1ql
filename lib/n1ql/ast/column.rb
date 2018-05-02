module N1ql
  module Ast
    class Column
      attr_reader :expression
      attr_accessor :as

      def initialize(expression, as = nil)
        @expression = expression
        @as = as
      end

      def to_json(*args)
        expression.to_json(*args)
      end

      def name(wildcard: nil)
        if as
          as
        elsif expression.respond_to?(:id)
          expression.id == '*' ? wildcard : expression.id
        end
      end

      def ==(other)
        if other.is_a?(self.class)
          expression == other.expression && as == other.as
        else
          expression == other
        end
      end

      def inspect
        "<Column expression:#{expression.inspect} as:#{as.inspect}>"
      end
    end
  end
end
