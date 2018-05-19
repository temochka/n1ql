RSpec.describe N1ql::Query do
  subject { N1ql::Query.new('SELECT 1') }

  it 'can be created' do
    is_expected.to be_a(N1ql::Query)
  end

  describe '#compile' do
    specify do
      is_expected.to compile_n1ql('SELECT 1').to(WHAT: [1]).with_titles('$1')
    end

    specify do
      is_expected.to compile_n1ql('SELECT 1, name, 2').to(WHAT: [1, %w(. name), 2]).with_titles('$1', 'name', '$2')
    end

    specify do
      is_expected.to compile_n1ql('SELECT name FROM table').
        to(WHAT: [%w(. name)], FROM: [{ as: 'table' }]).
        with_titles('name')
    end

    specify do
      is_expected.to compile_n1ql('SELECT name, GREATEST(width,depth) AS size FROM furniture ORDER BY size DESC').
        to(WHAT: [%w(. name), ['GREATEST()', %w(. width), %w(. depth)]],
           FROM: [{ as: 'furniture' }],
           ORDER_BY: [['DESC', %w(. size)]]).
        with_titles('name', 'size')
    end

    specify do
      is_expected.to compile_n1ql('SELECT * LIMIT $limit OFFSET 5 + 5').
        to(WHAT: [%w(.)],
           LIMIT: %w($ limit),
           OFFSET: ['+', 5, 5])
    end

    let(:lesson_1_1) do
      <<-SQL
        SELECT 'Hello World' AS Greeting
      SQL
    end

    it 'parses Lesson 1.1 query' do
      is_expected.to compile_n1ql(lesson_1_1).
        to(WHAT: ['Hello World']).
        with_titles('Greeting')
    end

    let(:lesson_1_2) do
      <<-SQL
        SELECT *
        FROM tutorial
        WHERE fname = 'Ian'
      SQL
    end

    it 'parses lesson 1.2 query' do
      is_expected.to compile_n1ql(lesson_1_2).
        to(WHAT: [%w(.)], FROM: [{ as: 'tutorial' }], WHERE: ['=', %w(. fname), 'Ian']).
        with_titles('tutorial')
    end

    let(:lesson_1_3) do
      <<-SQL
        SELECT children[0].fname AS child_name
        FROM tutorial
        WHERE fname='Dave'
      SQL
    end

    it 'parses lesson 1.3 query' do
      is_expected.to compile_n1ql(lesson_1_3).
        to(WHAT: [['.', 'children', [0], 'fname']],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['=', %w(. fname), 'Dave']).
        with_titles('child_name')
    end

    let(:lesson_1_4) do
      <<-SQL
        SELECT META(tutorial) AS meta
        FROM tutorial
      SQL
    end

    it 'parses lesson 1.4 query' do
      is_expected.to compile_n1ql(lesson_1_4).
        to(WHAT: [['META()', %w(. tutorial)]],
           FROM: [ as: 'tutorial' ]).
        with_titles('meta')
    end

    let(:lesson_1_5) do
      <<-SQL
        SELECT fname, age, age/7 AS age_dog_years 
        FROM tutorial 
        WHERE fname = 'Dave'
      SQL
    end

    it 'parses lesson 1.5 query' do
      is_expected.to compile_n1ql(lesson_1_5).
        to(WHAT: [%w(. fname), %w(. age), ['/', %w(. age), 7]],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['=', %w(. fname), 'Dave']).
        with_titles('fname', 'age', 'age_dog_years')
    end

    let(:lesson_1_6) do
      <<-SQL
        SELECT fname, age, ROUND(age/7) AS age_dog_years 
        FROM tutorial 
        WHERE fname = 'Dave'
      SQL
    end

    it 'parses lesson 1.6 query' do
      is_expected.to compile_n1ql(lesson_1_6).
        to(WHAT: [%w(. fname), %w(. age), ['ROUND()', ['/', %w(. age), 7]]],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['=', %w(. fname), 'Dave']).
        with_titles('fname', 'age', 'age_dog_years')
    end

    let(:lesson_1_7) do
      <<-SQL
        SELECT fname || " " || lname AS full_name
        FROM tutorial
      SQL
    end

    it 'parses lesson 1.7 query' do
      is_expected.to compile_n1ql(lesson_1_7).
        to(WHAT: [['||', %w(. fname), ['||', ' ', %w(. lname)]]], FROM: [{ as: 'tutorial'}]).
        with_titles('full_name')
    end

    let(:lesson_1_8) do
      <<-SQL
        SELECT fname, age 
        FROM tutorial
        WHERE age > 30
      SQL
    end

    it 'parses lesson 1.8 query' do
      is_expected.to compile_n1ql(lesson_1_8).
        to(WHAT: [%w(. fname), %w(. age)],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['>', %w(. age), 30]).
        with_titles('fname', 'age')
    end

    let(:lesson_1_9) do
      <<-SQL
        SELECT fname, email
        FROM tutorial 
        WHERE email LIKE '%@yahoo.com'
      SQL
    end

    it 'parses lesson 1.9 query' do
      is_expected.to compile_n1ql(lesson_1_9).
        to(WHAT: [%w(. fname), %w(. email)],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['LIKE', %w(. email), '%@yahoo.com']).
        with_titles('fname', 'email')
    end

    let(:lesson_1_10) do
      <<-SQL
        SELECT DISTINCT orderlines[0].productId
        FROM orders
      SQL
    end

    it 'parses lesson 1.10 query' do
      is_expected.to compile_n1ql(lesson_1_10).
        to(WHAT: [['.', 'orderlines', [0], 'productId']],
           DISTINCT: true,
           FROM: [{ as: 'orders' }]).
        with_titles('productId')
    end

    let(:lesson_1_11) do
      <<-SQL
        SELECT fname, children
        FROM tutorial 
        WHERE children IS NULL
      SQL
    end

    it 'parses lesson 1.11 query' do
      is_expected.to compile_n1ql(lesson_1_11).
        to(WHAT: [%w(. fname), %w(. children)],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['IS', %w(. children), nil]).
        with_titles('fname', 'children')
    end

    let(:lesson_1_12) do
      <<-SQL
        SELECT fname, children
        FROM tutorial 
        WHERE ANY child IN tutorial.children SATISFIES child.age > 10 END
      SQL
    end

    it 'parses lesson 1.12 query' do
      is_expected.to compile_n1ql(lesson_1_12).
        to(WHAT: [%w(. fname), %w(. children)],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['ANY', 'child', %w(. tutorial children), ['>', %w(. child age), 10]]).
        with_titles('fname', 'children')
    end

    let(:lesson_1_13) do
      <<-SQL
        SELECT fname, email, children
        FROM tutorial 
        WHERE ARRAY_LENGTH(children) > 0 AND email LIKE '%@gmail.com'
      SQL
    end

    it 'parses lesson 1.13 query' do
      is_expected.to compile_n1ql(lesson_1_13).
        to(WHAT: [%w(. fname), %w(. email), %w(. children)],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['AND', ['>', ['ARRAY_LENGTH()', %w(. children)], 0],
                   ['LIKE', %w(. email), '%@gmail.com']]).
        with_titles('fname', 'email', 'children')
    end

    let(:lesson_1_14) do
      <<-SQL
        SELECT fname, email
        FROM tutorial 
        USE KEYS ["dave", "ian"]
      SQL
    end

    it 'fails to parse lesson 1.14 query: CouchBase Lite doesn’t support key hints' do
      is_expected.to compile_n1ql(lesson_1_14).with_error(N1ql::ParserError)
    end

    let(:lesson_1_15) do
      <<-SQL
        SELECT children[0:2] 
        FROM tutorial 
        WHERE children[0:2] IS NOT MISSING
      SQL
    end

    it 'fails to parse lesson 1.15 query: CouchBase Lite doesn’t support slices' do
      is_expected.to compile_n1ql(lesson_1_15).with_error(N1ql::ParserError)
    end

    let(:lesson_1_16_altered) do
      <<-SQL
        SELECT fname || " " || lname AS full_name, email, children AS offspring
        FROM tutorial 
        WHERE email LIKE '%@yahoo.com' 
        OR ANY child IN tutorial.children SATISFIES child.age > 10 END
      SQL
    end

    it 'parses (altered) lesson 1.16 query (removed slices)' do
      is_expected.to compile_n1ql(lesson_1_16_altered).
        to(WHAT: [['||', %w(. fname), ['||', ' ', %w(. lname)]], %w(. email), %w(. children)],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['OR', ['LIKE', %w(. email), '%@yahoo.com'],
                         ['ANY', 'child', %w(. tutorial children), ['>', %w(. child age), 10]]]).
        with_titles('full_name', 'email', 'offspring')
    end

    let(:lesson_1_17) do
      <<-SQL
        SELECT fname, age 
        FROM tutorial 
        ORDER BY age
      SQL
    end

    it 'parses lesson 1.17 query' do
      is_expected.to compile_n1ql(lesson_1_17).
        to(WHAT: [%w(. fname), %w(. age)],
           FROM: [{ as: 'tutorial' }],
           ORDER_BY: [%w(. age)]).
        with_titles('fname', 'age')
    end

    let(:lesson_1_18) do
      <<-SQL
        SELECT fname, age
        FROM tutorial 
        ORDER BY age 
        LIMIT 2
      SQL
    end

    it 'parses lesson 1.18 query' do
      is_expected.to compile_n1ql(lesson_1_18).
        to(WHAT: [%w(. fname), %w(. age)],
           FROM: [{ as: 'tutorial' }],
           ORDER_BY: [%w(. age)],
           LIMIT: 2).
        with_titles('fname', 'age')
    end

    let(:lesson_1_19) do
      <<-SQL
        SELECT COUNT(*) AS count
        FROM tutorial
      SQL
    end

    it 'parses lesson 1.19 query' do
      is_expected.to compile_n1ql(lesson_1_19).
        to(WHAT: [['COUNT()', %w(.)]],
           FROM: [{ as: 'tutorial' }]).
        with_titles('count')
    end

    let(:lesson_1_20) do
      <<-SQL
        SELECT relation, COUNT(*) AS count
        FROM tutorial
        GROUP BY relation
      SQL
    end

    it 'parses lesson 1.20 query' do
      is_expected.to compile_n1ql(lesson_1_20).
        to(WHAT: [%w(. relation), ['COUNT()', %w(.)]],
           FROM: [{ as: 'tutorial' }],
           GROUP_BY: [%w(. relation)]).
        with_titles('relation', 'count')
    end

    let(:lesson_1_21) do
      <<-SQL
        SELECT relation, COUNT(*) AS count
        FROM tutorial
        GROUP BY relation
        HAVING COUNT(*) > 1
      SQL
    end

    it 'parses lesson 1.21 query' do
      is_expected.to compile_n1ql(lesson_1_21).
        to(WHAT: [%w(. relation), ['COUNT()', %w(.)]],
           FROM: [{ as: 'tutorial' }],
           GROUP_BY: [%w(. relation)],
           HAVING: ['>', ['COUNT()', %w(.)], 1]).
        with_titles('relation', 'count')
    end

    let(:lesson_1_22) do
      <<-SQL
        SELECT 
          fname AS parent_name,
          ARRAY child.fname FOR child IN tutorial.children END AS child_names
        FROM tutorial 
        WHERE children IS NOT NULL
      SQL
    end

    it 'parses lesson 1.22 query' do
      is_expected.to compile_n1ql(lesson_1_22).
        to(WHAT: [%w(. fname), ['ARRAY', %w(. child fname), 'child', %w(. tutorial children)]],
           FROM: [{ as: 'tutorial' }],
           WHERE: ['IS', %w(. children), ['NOT', nil]]).
        with_titles('parent_name', 'child_names')
    end

    let(:lesson_1_23_altered) do
      <<-SQL
        SELECT t.relation, COUNT(*) AS count, AVG(c.age) AS avg_age
        FROM t JOIN c
        WHERE c.age > 10
        GROUP BY t.relation
        HAVING COUNT(*) > 1
        ORDER BY avg_age DESC
        LIMIT 1
        OFFSET 1
      SQL
    end

    it 'parses lesson 1.23 (altered) query (Couchbase Lite doesn’t support UNNEST, replaced with JOIN)' do
      is_expected.to compile_n1ql(lesson_1_23_altered).
        to(WHAT: [%w(. t relation), ['COUNT()', %w(.)], ['AVG()', %w(. c age)]],
           FROM: [{ as: 't' }, { as: 'c' }],
           WHERE: ['>', %w(. c age), 10],
           GROUP_BY: [%w(. t relation)],
           HAVING: ['>', ['COUNT()', %w(.)], 1],
           ORDER_BY: [['DESC', %w(. avg_age)]],
           LIMIT: 1,
           OFFSET: 1).
        with_titles('relation', 'count', 'avg_age')
    end

    let(:lesson_2_1_altered) do
      <<-SQL
        SELECT usr.personal_details, orders
        FROM usr JOIN orders ON s.order_id IN usr.shipped_order_history
      SQL
    end

    it 'parses lesson 2.1 (altered) query (Couchbase Lite has limited JOIN support)' do
      is_expected.to compile_n1ql(lesson_2_1_altered).
        to(WHAT: [%w(. usr personal_details), %w(. orders)],
           FROM: [{ as: 'usr' },
                  { as: 'orders', on: ['IN', %w(. s order_id), %w(. usr shipped_order_history)] }]).
        with_titles('personal_details', 'orders')
    end

    let(:lesson_2_2) do
      <<-SQL
        SELECT usr.personal_details, orders
        FROM users_with_orders usr 
        USE KEYS "Tamekia_13483660" 
        LEFT JOIN orders_with_users orders 
        ON KEYS ARRAY s.order_id FOR s IN usr.shipped_order_history END
      SQL
    end

    it 'fails to parse lesson 2.2 query' do
      is_expected.to compile_n1ql(lesson_2_2).with_error(N1ql::ParserError)
    end

    let(:lesson_2_3) do
      <<-SQL
        SELECT usr.personal_details, orders
        FROM users_with_orders usr 
        USE KEYS "Elinor_33313792" 
        NEST orders_with_users orders 
        ON KEYS ARRAY s.order_id FOR s IN usr.shipped_order_history END
      SQL
    end

    it 'fails to parse lesson 2.3 query' do
      is_expected.to compile_n1ql(lesson_2_3).with_error(N1ql::ParserError)
    end

    let(:lesson_2_4) do
      <<-SQL
        SELECT * 
        FROM tutorial AS parent
        UNNEST parent.children
        WHERE parent.fname = 'Dave'
      SQL
    end

    it 'fails to parse lesson 2.4 query' do
      is_expected.to compile_n1ql(lesson_2_4).with_error(N1ql::ParserError)
    end

    let(:lesson_2_5) do
      <<-SQL
        SELECT  u.personal_details.display_name name, s AS order_no, o.product_details  
        FROM users_with_orders u USE KEYS "Aide_48687583" 
        UNNEST u.shipped_order_history s 
        JOIN users_with_orders o ON KEYS s.order_id
      SQL
    end

    it 'fails to parse lesson 2.5 query' do
      is_expected.to compile_n1ql(lesson_2_5).with_error(N1ql::ParserError)
    end
  end
end
