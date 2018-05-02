module N1ql
  module Ast
    class Path
      attr_reader :names

      def initialize(names)
        @names = names
      end

      def id
        @names.last&.id
      end

      def compile
        names.map(&:compile).unshift('.')
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
