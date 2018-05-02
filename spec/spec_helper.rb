require 'bundler/setup'
require 'parslet/rig/rspec'
require 'n1ql'
require 'pry'

RSpec::Matchers.define(:compile_n1ql) do |query_text, bindings = {}|
  actual_ast = nil
  actual_titles = nil
  actual_error = nil
  expected_ast = nil
  expected_titles = nil
  expected_error = nil
  query = nil
  ast_test = true
  titles_test = true
  error_test = true

  match do
    begin
      query = N1ql::Query.new(query_text)
      actual_titles = query.titles
      actual_ast = JSON.parse(query.compile(bindings), symbolize_names: true)

      ast_test = expected_ast && actual_ast == expected_ast || expected_ast.nil?
      titles_test = expected_titles && actual_titles == expected_titles || expected_titles.nil?
      error_test = expected_error.nil?

      ast_test && titles_test && error_test
    rescue => e
      actual_error = e
      raise e unless expected_error
      error_test = actual_error.is_a?(expected_error)
      error_test
    end
  end

  failure_message do
    if !ast_test
      "Expected #{query_text} to compile to following AST:\n" \
        "#{expected_ast.inspect}.\n\n" \
        "Actual AST:\n" \
        "#{actual_ast.inspect}\n\n"
    elsif !titles_test
      "Expected compiled #{query_text} to have titles: #{expected_titles.inspect}, got: #{actual_titles.inspect}."
    elsif !error_test
      "Expected error #{expected_error}, but got #{actual_error ? actual_error.class : 'no error'}."
    end
  end

  chain(:to) do |ast|
    expected_ast = ast
  end

  chain(:with_titles) do |*titles|
    expected_titles = titles
  end

  chain(:with_error) do |error|
    expected_error = error
  end
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
