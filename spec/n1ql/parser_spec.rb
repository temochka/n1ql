RSpec.describe N1ql::Parser do
  subject(:query_parser) { N1ql::Parser.new }

  it 'can be created' do
    expect(query_parser).to be_a(N1ql::Parser)
  end

  describe '#parse' do
    describe 'function' do
      subject(:parser) { query_parser.function }

      it { is_expected.to parse('COUNT(*)').as(function: { name: 'COUNT' }, arguments: [{ path: { name: '*' } }]) }

      it {
        is_expected.to parse('ARRAY_REPEAT(42, 5)').
          as(function: { name: 'ARRAY_REPEAT' }, arguments: [{ integer: '42' }, { integer: '5' }])
      }
    end

    describe 'NULL' do
      subject(:parser) { query_parser.null }

      it { is_expected.to parse('NULL').as(null: 'NULL') }
    end

    describe 'boolean' do
      subject(:parser) { query_parser.boolean }

      it { is_expected.to parse('TRUE').as(boolean: 'TRUE') }
      it { is_expected.to parse('FALSE').as(boolean: 'FALSE') }
    end

    describe 'number' do
      subject(:parser) { query_parser.number }

      it { is_expected.to parse('0').as(integer: '0') }
      it { is_expected.to parse('-0').as(integer: '-0') }
      it { is_expected.to parse('12345678').as(integer: '12345678') }
      it { is_expected.to parse('-1').as(integer: '-1') }

      it { is_expected.to parse('0.').as(float: '0.') }
      it { is_expected.to parse('-0.').as(float: '-0.') }
      it { is_expected.to parse('-1.0').as(float: '-1.0') }
      it { is_expected.to parse('123.456').as(float: '123.456') }
      it { is_expected.to parse('123.0').as(float: '123.0') }

      it { is_expected.to_not parse('0123') }
      it { is_expected.to_not parse('0123.') }
    end

    describe 'string' do
      subject(:parser) { query_parser.string }

      it { is_expected.to parse('"foo\\""').as(string: 'foo"') }
      it { is_expected.to parse("'foo\\''").as(string: "foo'") }
    end

    describe 'array' do
      subject(:parser) { query_parser.array }

      it { is_expected.to parse('[]').as(array: '') }

      it { is_expected.to parse('[   ]').as(array: '') }

      it {
        is_expected.to parse('[1, 2 ,3 , 4]').
          as(array: [{ integer: '1' }, { integer: '2' }, { integer: '3' }, { integer: '4' }])
      }

      it {
        is_expected.to parse('[1+2, 3.0, "foo"]').
          as(array: [{ o: '+', l: { integer: '1' }, r: { integer: '2' } },
                     { float: '3.0' },
                     { string: 'foo' }])
      }
    end

    describe 'object' do
      subject(:parser) { query_parser.object }

      it { is_expected.to parse('{}').as(object: '') }
      it { is_expected.to parse('{  }').as(object: '') }

      it {
        is_expected.to parse('{"number": 1, "array": [], UPPER("foo") : 1}').
          as(object: [{ field: { string: 'number' }, value: { integer: '1' } },
                      { field: { string: 'array' }, value: { array: '' } },
                      { field: { function: { name: 'UPPER' }, arguments: [{ string: 'foo' }] }, value: { integer: '1' } }])
      }
    end

    %w(ANY EVERY).each do |pred|
      describe "#{pred} operator" do
        subject(:parser) { query_parser.op_array_pred }

        it {
          is_expected.to parse("#{pred} departure IN schedule, foo IN bar SATISFIES departure.utc > foo END").
            as(opname: pred,
               bindings: [
                 { l: { name: 'departure' }, r: { path: { name: 'schedule' } } },
                 { l: { name: 'foo' }, r: { path: { name: 'bar' } } }
               ],
               predicate: {
                 o: '>',
                 l: { path: [{ name: 'departure' }, { name: 'utc' }] },
                 r: { path: { name: 'foo' } }
               })
        }
      end
    end

    describe 'ARRAY operator' do
      subject(:parser) { query_parser.op_array }

      it {
        is_expected.to parse('ARRAY v FOR v IN schedule WHEN v.utc > "19:00" AND v.day = 5 END').
          as(opname: 'ARRAY',
             array_expression: { path: { name: 'v' } },
             bindings: [
               { l: { name: 'v' }, r: { path: { name: 'schedule' } } }
             ],
             predicate: {
               o: 'AND',
               l: {
                 o: '>',
                 l: { path: [{ name: 'v' }, { name: 'utc' }] },
                 r: { string: '19:00' }
               },
               r: {
                  o: '=',
                  l: { path: [{ name: 'v' }, { name: 'day' }] },
                  r: { integer: '5' }
               }
             })
      }
    end

    describe 'CASE operator (simple)' do
      subject(:parser) { query_parser.op_case }

      it {
        is_expected.to parse('CASE `shipped-on` WHEN "23:00" THEN `shipped-on` ELSE "not-shipped-yet" END').
          as(opname: 'CASE',
             simple_case: { path: { name: 'shipped-on' } },
             bindings: [
               { l: { string: '23:00' }, r: { path: { name: 'shipped-on' } } }
             ],
             else: { string: 'not-shipped-yet' })
      }
    end

    describe 'name' do
      subject(:parser) { query_parser.name }

      it { is_expected.to_not parse('2Pac').as(name: '2Pac') }
      it { is_expected.to parse('Sting').as(name: 'Sting') }
      it { is_expected.to parse('Thirty6Kealo').as(name: 'Thirty6Kealo') }
      it { is_expected.to parse('`King William III`').as(name: 'King William III') }
    end

    describe 'path' do
      subject(:parser) { query_parser.path }

      it { is_expected.to parse('Buckethead[1]').as(path: [{ name: 'Buckethead' }, { index: { integer: '1' } }]) }
      it { is_expected.to parse('Buckethead  [11]').as(path: [{ name: 'Buckethead' }, { index: { integer: '11' } }]) }
      it { is_expected.to parse('`Buckethead[2]`[1]').as(path: [ { name: 'Buckethead[2]' }, { index: { integer: '1' } } ]) }
      it { is_expected.to parse('`Spice Girls`[1]').as(path: [{ name: 'Spice Girls'}, { index: { integer: '1' } }]) }

      it {
        is_expected.to parse('foo.bar . buz').
          as(path: [{ name: 'foo' }, { name: 'bar' }, { name: 'buz' }])
      }
      it { is_expected.to parse('a.b[2]').as(path: [{ name: 'a' }, { name: 'b' }, { index: { integer: '2' } }]) }
      it { is_expected.to parse('`a b`.`c d`').as(path: [{ name: 'a b' }, { name: 'c d' }]) }
    end

    describe 'expression' do
      subject(:parser) { query_parser.expression }

      it { is_expected.to parse('name').as(path: { name: 'name' }) }
      it { is_expected.to parse('name.attribute').as(path: [{ name: 'name' }, { name: 'attribute' }]) }
      it { is_expected.to parse('(((name)))').as(path: { name: 'name' }) }
      it { is_expected.to parse('COUNT(*)').as(function: { name: 'COUNT' }, arguments: [{ path: { name: '*' } }]) }
      it { is_expected.to parse('42').as(integer: '42') }
      it { is_expected.to parse('NOT flag').as(op_not: { path: { name: 'flag' } }) }
      it { is_expected.to parse('$name').as(parameter: { name: 'name' }) }
      it { is_expected.to parse('$object.value').as(parameter: [{ name: 'object' }, { name: 'value' }]) }

      %w(/ * + - % LIKE).each do |op|
        it { is_expected.to parse("age #{op} 2").as(o: op, l: { path: { name: 'age' } }, r: { integer: '2' }) }
      end

      it { is_expected.to parse('ARRAY child.fname FOR child IN tutorial.children END') }

      it {
        is_expected.to parse('(1+2)/(4-5*6) || "geese"').
          as(o: '||',
             l: {
               o: '/',
               l: {
                 o: '+',
                 l: { integer: '1' },
                 r: { integer: '2' }
               },
               r: {
                 o: '-',
                 l: { integer: '4' },
                 r: {
                   o: '*',
                   l: { integer: '5' },
                   r: { integer: '6' }
                 }
               }
             },
             r: { string: 'geese' })
      }
    end

    describe 'columns' do
      subject(:parser) { query_parser.columns }

      specify do
        is_expected.to parse('*').as(column: { path: { name: '*' } }, as: nil )
      end

      specify do
        is_expected.to parse('column').as(column: { path: { name: 'column' } }, as: nil )
      end

      specify do
        is_expected.to parse('pipe AS not_pipe', trace: true).
          as(column: { path: { name: 'pipe' } },
             as: { name: 'not_pipe' })
      end

      specify do
        is_expected.to parse('column1,column2, column3 ,column4 , column5').
          as([{ column: { path: { name: 'column1' } }, as: nil  },
              { column: { path: { name: 'column2' } }, as: nil  },
              { column: { path: { name: 'column3' } }, as: nil  },
              { column: { path: { name: 'column4' } }, as: nil  },
              { column: { path: { name: 'column5' } }, as: nil  }])
      end

      it { is_expected.to parse('ARRAY child.fname FOR child IN tutorial.children END AS foo', trace: true) }
    end

    describe 'FROM' do
      subject(:parser) { query_parser.data_sources }

      it { is_expected.to parse('user').as(as: { name: 'user' }) }
      it {
        is_expected.to parse('user JOIN receipt').
          as([{ as: { name: 'user' } },
              { as: { name: 'receipt' } }])
      }
      it {
        is_expected.to parse('user JOIN receipt ON receipt.user_id=user.id').
          as([{ as: { name: 'user' } },
              { as: { name: 'receipt' },
                on: { o: '=',
                      l: { path: [{ name: 'receipt' }, { name: 'user_id' }] },
                      r: { path: [{ name: 'user' }, { name: 'id' }] } }}])
      }
    end

    describe 'ORDER BY' do
      subject(:parser) { query_parser.order_by }

      it { is_expected.to parse('price').as(order_expression: { path: { name: 'price' } }, order_direction: nil) }
      it { is_expected.to parse('price ASC').as(order_expression: { path: { name: 'price' } }, order_direction: 'ASC') }
      it { is_expected.to parse('price DESC').as(order_expression: { path: { name: 'price' } }, order_direction: 'DESC') }
      it {
        is_expected.to parse('quantity DESC, price ASC', trace: true).
          as([{ order_expression: { path: { name: 'quantity' } }, order_direction: 'DESC' },
              { order_expression: { path: { name: 'price' } }, order_direction: 'ASC' }])
      }
    end

    describe 'SELECT query' do
      subject(:parser) { query_parser.select }

      let(:barebone) { { what: nil, distinct: nil, from: nil, where: nil, having: nil, group_by: nil, order_by: nil, limit: nil, offset: nil } }

      it {
        is_expected.to parse('SELECT 1').
          as(barebone.merge(what: { column: { integer: '1' }, as: nil }))
      }

      it {
        is_expected.to parse('SELECT name FROM users').
          as(barebone.merge(what: { column: { path: { name: 'name' } }, as: nil },
                            from: { as: { name: 'users' } }))
      }

      it {
        is_expected.to parse('SELECT * WHERE 1=1').
          as(barebone.merge(what: { column: { path: { name: '*' } }, as: nil },
                           where: { o: '=', l: { integer: '1' }, r: { integer: '1' } }))
      }

      it {
        is_expected.to parse('SELECT * GROUP BY name').
          as(barebone.merge(what: { column: { path: { name: '*' } }, as: nil },
                            group_by: { path: { name: 'name' } }))
      }

      it {
        is_expected.to parse('SELECT name, COUNT(*) GROUP BY name HAVING COUNT(*) > 3').
          as(barebone.merge(what: [{ column: { path: { name: 'name' } }, as: nil },
                                   { column: { function: { name: 'COUNT' }, arguments: [{ path: { name: '*' } }] }, as: nil }],
                            group_by: { path: { name: 'name' } },
                            having: { o: '>', l: { function: { name: 'COUNT' }, arguments: [{ path: { name: '*' } }] }, r: { integer: '3' } }))
      }

      it {
        is_expected.to parse('SELECT * ORDER BY name', trace: true).
          as(barebone.merge(what: { column: { path: { name: '*' } }, as: nil },
                            order_by: { order_expression: { path: { name: 'name' } },
                                        order_direction: nil }))
      }

      it {
        is_expected.to parse('SELECT * LIMIT 10 OFFSET 20').
          as(barebone.merge(what: { column: { path: { name: '*' } }, as: nil },
                            offset: { integer: '20' },
                            limit: { integer: '10' }))
      }

      it {
        is_expected.to parse('SELECT DISTINCT age').
          as(barebone.merge(what: { column: { path: { name: 'age' } }, as: nil },
                            distinct: 'DISTINCT'))
      }
    end
  end
end
