module N1ql
  module Ast
    class Placeholder
      attr_reader :name

      def initialize(name, bindings)
        @name = name
        @bindings = bindings
      end

      def ==(other)
        if other.is_a?(self.class)
          other.name == name
        else
          value == other
        end
      end

      def value
        @bindings.fetch(name)
      end

      def to_json(*args)
        value.to_json(*args)
      end
    end
  end
end
