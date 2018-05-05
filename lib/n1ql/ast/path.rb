module N1ql
  module Ast
    class Path
      attr_reader :names, :operator

      def initialize(names, operator = '.')
        @names = names.reject(&:empty?)
        @operator = operator
      end

      def id
        @names.last&.id || ''
      end

      def compile
        names.map(&:compile).unshift(operator)
      end

      def ==(other)
        case other
        when Array
          compile == other
        when self.class
          names == other.names
        end
      end

      def to_json(*args)
        compile.to_json(*args)
      end
    end
  end
end
