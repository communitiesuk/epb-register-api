describe "UseCase::CreateCipFile" do

  context "read degrees day data stored by the Met offiaddce " do
    subject { UseCase::CreateCipFile.new }

    it 'read the object' do
      expect{subject.execute}.not_to raise_error
    end
  end
end
