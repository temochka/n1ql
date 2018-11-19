RSpec.describe N1ql::Precompiler do
  subject(:precompiler) { N1ql::Precompiler.new }

  it 'can be created' do
    is_expected.to be_a(N1ql::Precompiler)
  end

  describe '#compile' do
    def compile(ast)
      precompiler.apply(ast)
    end

    describe 'NULL' do
      specify { expect(compile(null: 'NULL')).to be_nil }
    end

    describe 'MISSING' do
      specify { expect(compile(missing: 'MISSING')).to eq(%w(MISSING)) }
    end

    describe 'boolean' do
      specify { expect(compile(boolean: 'TRUE')).to eq(true) }
      specify { expect(compile(boolean: 'true')).to eq(true) }
      specify { expect(compile(boolean: 'FALSE')).to eq(false) }
      specify { expect(compile(boolean: 'false')).to eq(false) }
    end

    describe 'number' do
      specify { expect(compile(integer: '1234567')).to eq(1234567) }
      specify { expect(compile(float: '12.08')).to eq(12.08) }
    end

    describe 'string' do
      specify { expect(compile(string: 'foo')).to eq('foo') }
    end

    describe 'array' do
      specify { expect(compile(array: [{ integer: '42' }, { string: 'foo' }])).to eq(['[]', 42, 'foo']) }
    end

    describe 'object' do
      specify do
        expect(compile(object: [{ field: { string: 'foo' }, value: { integer: '42' } }])).
          to eq('foo' => 42)
      end
    end

    describe 'name' do
      specify { expect(compile(name: 'name')).to eq('name') }
      specify { expect(compile(name: '*')).to be_empty }
    end

    describe 'path' do
      specify { expect(compile(path: [{ name: 'foo' }, { name: 'bar' }])).to eq(%w(. foo bar)) }
      specify { expect(compile(path: [{ name: 'foo' }, { index: { integer: '0' } }])).to eq(['.', 'foo', [0]]) }
      specify { expect(compile(path: [{ name: '*' }])).to eq(['.']) }
    end

    describe 'parameter' do
      specify { expect(compile(parameter: { name: 'foo' })).to eq(%w($ foo)) }
      specify { expect(compile(parameter: [{ name: 'foo' }, { name: 'bar' }])).to eq(%w($ foo bar)) }
    end

    describe 'operator' do
      specify { expect(compile(o: '+', l: { integer: '2' }, r: { integer: '3' })).to eq(['+', 2, 3]) }
    end

    describe 'function' do
      specify do
        expect(compile(function: { name: 'COUNT' }, arguments: [{ path: [{ name: '*' }] }])).to eq(['COUNT()', %w(.)])
      end
    end

    describe 'ANY, EVERY' do
      %w(ANY EVERY).each do |pred|
        specify do
          expect(compile(opname: pred,
                         bindings: [
                           { l: { name: 'departure' }, r: { path: { name: 'schedule' } } },
                           { l: { name: 'foo' }, r: { path: { name: 'bar' } } }
                         ],
                         predicate: {
                           o: '>',
                           l: { path: [{ name: 'departure' }, { name: 'utc' }] },
                           r: { path: { name: 'foo' } }
                         })).
            to eq([pred, 'departure', %w(. schedule), 'foo', %w(. bar), ['>', %w(. departure utc), %w(. foo)]])
        end
      end
    end

    describe 'NOT' do
      specify { expect(compile(op_not: { boolean: 'TRUE' })).to eq(['NOT', true]) }
    end

    describe 'column' do
      specify { expect(compile(column: { name: 'name' }, as: nil).name).to eq('name') }
      specify { expect(compile(column: { name: 'foo' }, as: 'bar').name).to eq('bar') }
    end

    describe 'query' do
      let(:barebone) { { distinct: nil, what: nil, from: nil, where: nil, group_by: nil, having: nil, order_by: nil, limit: nil, offset: nil } }

      specify { expect(compile(barebone.merge(from: { as: { name: 'foo' } }))).to eq(FROM: [{ as: 'foo' }])}

      it 'compiles ASC order expressions to expressions' do
        [nil, 'ASC'].each do |d|
          ast = barebone.merge(order_by: { order_expression: { path: [{ name: 'foo' }] }, order_direction: d })
          expect(compile(ast)).to eq(ORDER_BY: [%w(. foo)])
        end
      end

      it 'wraps DESC order expressions into an operator' do
        ast = barebone.merge(order_by: { order_expression: { path: [{ name: 'foo' }] }, order_direction: 'DESC' })
        expect(compile(ast)).to eq(ORDER_BY: [['DESC', %w(. foo)]])
      end
    end
  end
end
