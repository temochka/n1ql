module N1ql
  class Bindings
    attr_reader :values

    def initialize
      @values = {}
      @lock = Monitor.new
    end

    def with_values(values)
      @lock.synchronize { swap(values) { yield } }
    end

    def fetch(name)
      values.fetch(name.to_s)
    rescue KeyError
      raise NameError, "Undefined value ?#{name}?"
    end

    private

    def values=(hash)
      raise ArgumentError, 'Bindings must be a Hash' unless hash.is_a?(Hash)

      @values = hash.each_with_object({}) do |(k, v), compiled|
        compiled[k.to_s] = compile_value(k, v)
      end
    end

    def compile_value(name, val)
      case val
      when Array
        val.unshift('[]')
      when Hash, Numeric, String, TrueClass, FalseClass
        val
      else
        raise ArgumentError, "Unsupported binding type #{val.class} for #{name}."
      end
    end

    def swap(values)
      self.values = values
      yield
    ensure
      self.values = {}
    end
  end
end
