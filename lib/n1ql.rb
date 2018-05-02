require 'delegate'
require 'json'
require 'monitor'
require 'parslet'

require 'n1ql/ast/column'
require 'n1ql/ast/lookup'
require 'n1ql/ast/name'
require 'n1ql/ast/node'
require 'n1ql/ast/path'
require 'n1ql/ast/placeholder'
require 'n1ql/bindings'
require 'n1ql/parser'
require 'n1ql/precompiler'
require 'n1ql/query'
require 'n1ql/version'

module N1ql
  class Error < StandardError; end
  class ParserError < Error; end
  class NameError < Error; end

  def self.parse(expression)
    Query.new(expression)
  end
end
