# frozen_string_literal: true

describe UseCase::AddAssessor do
  let(:valid_assessor) do
    {
      first_name: 'John',
      last_name: 'Smith',
      middle_names: 'Brain',
      date_of_birth: '1991-02-25',
      search_results_comparison_postcode: 'E2 0SZ'
    }
  end

  let(:valid_assessor_with_contact_details) do
    {
      first_name: 'John',
      last_name: 'Doe',
      middle_names: 'Brain',
      date_of_birth: '1991-02-25',
      contact_details: {
        telephone_number: '004622416767', email: 'mar@ten.com'
      },
      search_results_comparison_postcode: 'E2 0SZ',
      qualifications: { domestic_energy_performance_certificates: 'ACTIVE' }
    }
  end

  context 'when adding an assessor' do
    let(:add_assessor_with_stub_data) do
      schemes_gateway =
        SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
      described_class.new(schemes_gateway, AssessorGatewayFake.new(nil))
    end

    it 'returns an error if the scheme doesnt exist' do
      schemes_gateway = SchemesGatewayStub.new([])
      add_assessor =
        described_class.new(schemes_gateway, AssessorGatewayFake.new(nil))
      expect {
        add_assessor.execute('6', 'SCHE24352', valid_assessor)
      }.to raise_exception(UseCase::AddAssessor::SchemeNotFoundException)
    end

    it 'returns no errors if the scheme does exist' do
      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE904572', valid_assessor)
      }.to_not raise_exception
    end

    it 'returns the scheme that the assessor belongs to' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', valid_assessor)[
          :assessor
        ][
          :registered_by
        ]
      ).to eq(scheme_id: '25', name: 'Best scheme')
    end

    it 'returns the scheme assessor ID' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', valid_assessor)[
          :assessor
        ][
          :scheme_assessor_id
        ]
      ).to eq('SCHE234950')
    end

    it 'returns the assessors first name' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', valid_assessor)[
          :assessor
        ][
          :first_name
        ]
      ).to eq('John')
    end

    it 'returns the assessors last name' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', valid_assessor)[
          :assessor
        ][
          :last_name
        ]
      ).to eq('Smith')
    end

    it 'returns the assessors middle names' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', valid_assessor)[
          :assessor
        ][
          :middle_names
        ]
      ).to eq('Brain')
    end

    it 'returns the assessors date of birth' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', valid_assessor)[
          :assessor
        ][
          :date_of_birth
        ]
      ).to eq('1991-02-25')
    end

    it 'returns the assessors contact details if present' do
      expect(
        add_assessor_with_stub_data.execute(
          '25',
          'SCHE234950',
          valid_assessor_with_contact_details
        )[
          :assessor
        ][
          :contact_details
        ]
      ).to eq({ telephone_number: '004622416767', email: 'mar@ten.com' })
    end

    it 'returns the assessors qualifications' do
      expect(
        add_assessor_with_stub_data.execute(
          '25',
          'SCHE234950',
          valid_assessor_with_contact_details
        )[
          :assessor
        ][
          :qualifications
        ]
      ).to eq({ domestic_energy_performance_certificates: 'ACTIVE' })
    end

    it 'does not return an error if middle names are missing' do
      assessor_without_middle_names = valid_assessor.dup
      assessor_without_middle_names.delete(:middle_names)
      expect {
        add_assessor_with_stub_data.execute(
          '25',
          'SCHE2435',
          assessor_without_middle_names
        )
      }.to_not raise_exception
    end

    it 'saves the assessors details' do
      schemes_gateway =
        SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
      assessor_gateway = AssessorGatewayFake.new(nil)
      add_assessor_with_spy =
        described_class.new(schemes_gateway, assessor_gateway)
      add_assessor_with_spy.execute('25', 'SCHE4353', valid_assessor)
      expect(assessor_gateway.saved_assessor_details).to eq(valid_assessor)
    end

    it 'returns true when assessor already exists' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', valid_assessor)[
          :assessor_was_newly_created
        ]
      ).to be true
    end
  end

  context 'when adding with same ID from another scheme' do
    it 'returns an error' do
      schemes_gateway =
        SchemesGatewayStub.new(
          [
            { scheme_id: 25, name: 'Best scheme' },
            { scheme_id: 26, name: 'Worst scheme' }
          ]
        )
      assessor_gateway =
        AssessorGatewayFake.new(
          {
            registered_by: { scheme_id: 25, name: 'Best scheme' },
            scheme_assessor_id: 'SCHE001',
            first_name: valid_assessor[:first_name],
            last_name: valid_assessor[:last_name],
            date_of_birth: valid_assessor[:date_of_birth]
          }
        )

      add_assessor = described_class.new(schemes_gateway, assessor_gateway)

      expect {
        add_assessor.execute(26, 'SCHE001', valid_assessor)
      }.to raise_exception(
        UseCase::AddAssessor::AssessorRegisteredOnAnotherScheme
      )
    end
  end

  context 'when updating an assessor' do
    let(:add_assessor_with_stub_data) do
      schemes_gateway =
        SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
      described_class.new(
        schemes_gateway,
        AssessorGatewayFake.new(
          {
            registered_by: 25,
            scheme_assessor_id: 'SCHE234950',
            first_name: 'John',
            last_name: 'Smith',
            middle_names: 'Brain',
            date_of_birth: '1991-02-25'
          }
        )
      )
    end

    it 'assessor_was_newly_created is false when assessor already exists' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', valid_assessor)[
          :assessor_was_newly_created
        ]
      ).to be false
    end
  end

  context 'when adding with invalid data' do
    let(:add_assessor_with_stub_data) do
      schemes_gateway =
        SchemesGatewayStub.new([{ scheme_id: 25, name: 'Best scheme' }])
      described_class.new(schemes_gateway, AssessorGatewayFake.new(nil))
    end
  end
end
