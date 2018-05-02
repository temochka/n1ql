module N1ql
  class Query
    attr_reader :text, :ast, :titles

    def initialize(text)
      @text = text
      @parser = Parser.new
      @bindings = Bindings.new
      @precompiler = Precompiler.new(bindings: @bindings)
      @ast = @precompiler.apply(@parser.parse(@text), bindings: @bindings)
      @titles = extract_titles(@ast)
    rescue Parslet::ParseFailed => error
      raise ParserError, error.parse_failure_cause.ascii_tree
    end

    def compile(bindings = {})
      @bindings.with_values(bindings) { @ast.to_json }
    end

    private

    def extract_titles(ast)
      index = 0
      first_data_source = ast.fetch(:FROM, []).first&.fetch(:as, nil)
      ast[:WHAT].map do |column|
        column.name(wildcard: first_data_source) || "$#{index += 1}"
      end.map(&:to_s)
    end
  end
end
