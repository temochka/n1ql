module N1ql
  module Ast
    class Name
      attr_reader :name
      alias_method :id, :name
      alias_method :to_s, :name
      alias_method :compile, :name

      def initialize(name)
        @name = name
      end

      def to_json(*args)
        compile.to_json(*args)
      end

      def ==(other)
        case other
        when String
          id == other
        when self.class
          id == other.id
        end
      end
    end
  end
end
