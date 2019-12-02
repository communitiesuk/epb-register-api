describe Helper::JsonHelper do
  HELPER = described_class.new

  context 'when converting json to ruby hashes' do
    it 'changes top level keys to symbols' do
      result = HELPER.convert_to_ruby_hash({"foo" => "Bar"}.to_json)
      expect(result.keys).to include(:foo)
    end

    it 'changes nested keys to symbols' do
      result = HELPER.convert_to_ruby_hash({"foo" => {"bar" => "baz"}}.to_json)
      expect(result[:foo].keys).to include(:bar)
    end

    it 'changes top level keys to snake case' do
      result = HELPER.convert_to_ruby_hash({"fooBar" => "baz"}.to_json)
      expect(result.keys).to include(:foo_bar)
    end

    it 'changes nested level keys to snake case' do
      result = HELPER.convert_to_ruby_hash({"fooBar" => {"barBaz" => "boo"}}.to_json)
      expect(result.keys).to include(:foo_bar)
      expect(result[:foo_bar].keys).to include(:bar_baz)
    end
  end
end
