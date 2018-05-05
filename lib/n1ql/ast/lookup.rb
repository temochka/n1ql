module N1ql
  module Ast
    class Lookup
      attr_reader :index

      def initialize(index)
        @index = index
      end

      def id
        nil
      end

      def empty?
        false
      end

      def compile
        [index]
      end

      def to_json(*args)
        compile.to_json(*args)
      end

      def ==(other)
        case other
        when self.class
          index == other.index
        when Array
          compile == other
        end
      end
    end
  end
end