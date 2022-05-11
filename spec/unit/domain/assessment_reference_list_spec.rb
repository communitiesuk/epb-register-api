describe Domain::AssessmentReferenceList do
  context "with no references" do
    it "has a count of zero" do
      expect(described_class.new.count).to eq 0
    end
  end

  context "with three references" do
    references = %w[0000-0000-0000-0000-0002 0000-0000-0000-0000-0034 0000-0000-0000-0000-0501]

    subject(:list) { described_class.new(*references) }

    it "has a count of three" do
      expect(list.count).to eq 3
    end

    it "iterates through the references" do
      expect(list.map { |i| i }).to eq references
    end

    it "can return the references with a #references method call" do
      expect(list.references).to eq references
    end
  end

  context "with two references provided in descending order" do
    references = %w[0000-0000-0000-0000-0003 0000-0000-0000-0000-0002]

    subject(:list) { described_class.new(*references) }

    it "returns the references in a sorted order" do
      expect(list.references).to eq references.sort
    end
  end
end
