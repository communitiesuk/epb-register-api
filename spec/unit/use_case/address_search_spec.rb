describe UseCase::SearchAddressesByStreetAndTown do

  include RSpecRegisterApiServiceMixin

  context 'When searching the same address in both the assessments and address_base tables' do
    subject {UseCase::SearchAddressesByStreetAndTown.new}

    before do
      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
          nonDomesticDec: "ACTIVE",
          domesticRdSap: "ACTIVE",
          domesticSap: "ACTIVE",
          nonDomesticSp3: "ACTIVE",
          nonDomesticCc4: "ACTIVE",
          gda: "ACTIVE",
          ),
        )

      assessment=Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"

      lodge_assessment(
        assessment_body:assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
        )


      insert_into_address_base('000000000000', 'A0 0AA', '1 Some Street', '',  'Whitbury')



    end

    it 'returns only one address for the relevant property ' do
      result = subject.execute(street:'1 Some Street', town: "Whitbury")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000000000000")
      expect(result.first.line1).to eq("1 Some Street")
      expect(result.first.town).to eq("Whitbury")
      expect(result.first.postcode).to eq("A0 0AA")
    end

  end


  context 'When searching an address not found in the assessment but present in address base' do

    before do
      insert_into_address_base('000000000001', 'SW1V 2SS', '2 Some Street', '',  'London')
    end

    it 'returns a single address line from address base ' do
      result = subject.execute(street:'2 Some Street', town: "London")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000000000001")
      expect(result.first.line1).to eq("2 Some Street")
      expect(result.first.town).to eq("London")
      expect(result.first.postcode).to eq("SW1V 2SS")
    end

    it 'returns an address from address base with a fuzzy look up' do
      result = subject.execute(street:'Some', town: "London")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000000000001")
    end

  end


  context 'When searching for an address with many results' do

    before do
      insert_into_address_base('000005689782', 'SW1V 2SS', '2b Some Street', '',  'London')
      insert_into_address_base('078956456456', 'SW1V 2SS', 'Main Office', '2 Some Street',  'London')
      insert_into_address_base('000896454564', 'SW1V 2SS', '1 Some Street', '',  'London')

    end

      it 'finds all 3 rows in the correct order' do
        result = subject.execute(street:'Some', town: "London")
        expect(result.length).to eq(3)
        expect(result.first.address_id).to eq("UPRN-000896454564")
        expect(result[1].address_id).to eq("UPRN-000005689782")
        expect(result[2].address_id).to eq("UPRN-078956456456")
      end

  end


  context 'When there are the same addresses in both the assessments and address base' do

    before do
      insert_into_address_base('000005689782', 'SW1 2AA', 'Flat 3', '1 Some Street', 'London')

      scheme_id = add_scheme_and_get_id
      add_assessor(
        scheme_id,
        "SPEC000000",
        AssessorStub.new.fetch_request_body(
          nonDomesticNos3: "ACTIVE",
          nonDomesticNos4: "ACTIVE",
          nonDomesticNos5: "ACTIVE",
          nonDomesticDec: "ACTIVE",
          domesticRdSap: "ACTIVE",
          domesticSap: "ACTIVE",
          nonDomesticSp3: "ACTIVE",
          nonDomesticCc4: "ACTIVE",
          gda: "ACTIVE",
          ),
        )

      domestic_assessment = Nokogiri.XML Samples.xml "RdSAP-Schema-20.0.0"

      lodge_assessment(
        assessment_body:domestic_assessment.to_xml,
        accepted_responses: [201],
        auth_data: {
          scheme_ids: [scheme_id],
        },
        ensure_uprns: false,
        )

    end


    it 'returns only the address from address base not from the assesment' do
      result = subject.execute(street:'Some', town: "London")
      expect(result.length).to eq(1)
      expect(result.first.address_id).to eq("UPRN-000005689782")
    end

  end


end






