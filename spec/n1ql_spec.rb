RSpec.describe N1ql do
  it 'has a version number' do
    expect(N1ql::VERSION).not_to be nil
  end

  let(:expression) { 'SELECT * FROM users' }

  describe '.parse' do
    it 'builds a Query from a given expression' do
      expect(N1ql.parse(expression)).to be_an(N1ql::Query)
    end
  end
end
