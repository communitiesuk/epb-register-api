# frozen_string_literal: true

describe UseCase::AddAssessor do
  VALID_ASSESSOR = {
    first_name: 'John',
    last_name: 'Smith',
    middle_names: 'Brain',
    date_of_birth: '1991-02-25'
  }.freeze

  class SchemesGatewayStub
    def initialize(result)
      @result = result
    end

    def all(*)
      @result
    end
  end

  class AssessorGatewayFake
    attr_reader :saved_assessor_details,
                :saved_registered_by,
                :saved_scheme_assessor_id

    def initialize(result)
      @result = result
      @saved_scheme_assessor_id = false
      @saved_assessor_details = false
      @saved_registered_by = false
    end

    def fetch(*)
      @result
    end

    def update(scheme_assessor_id, registered_by, assessor_details)
      @saved_scheme_assessor_id = scheme_assessor_id
      @saved_assessor_details = assessor_details
      @saved_registered_by = registered_by
    end
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
        add_assessor.execute('6', 'SCHE24352', VALID_ASSESSOR)
      }.to raise_exception(UseCase::AddAssessor::SchemeNotFoundException)
    end

    it 'returns no errors if the scheme does exist' do
      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE904572', VALID_ASSESSOR)
      }.to_not raise_exception
    end

    it 'returns the scheme that the assessor belongs to' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', VALID_ASSESSOR)[
          :assessor
        ][
          :registered_by
        ]
      ).to eq(scheme_id: '25', name: 'Best scheme')
    end

    it 'returns the scheme assessor ID' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', VALID_ASSESSOR)[
          :assessor
        ][
          :scheme_assessor_id
        ]
      ).to eq('SCHE234950')
    end

    it 'returns the assessors first name' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', VALID_ASSESSOR)[
          :assessor
        ][
          :first_name
        ]
      ).to eq('John')
    end

    it 'returns the assessors last name' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', VALID_ASSESSOR)[
          :assessor
        ][
          :last_name
        ]
      ).to eq('Smith')
    end

    it 'returns the assessors middle names' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', VALID_ASSESSOR)[
          :assessor
        ][
          :middle_names
        ]
      ).to eq('Brain')
    end

    it 'returns the assessors date of birth' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', VALID_ASSESSOR)[
          :assessor
        ][
          :date_of_birth
        ]
      ).to eq('1991-02-25')
    end

    it 'does not return an error if middle names are missing' do
      assessor_without_middle_names = VALID_ASSESSOR.dup
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
      add_assessor_with_spy.execute('25', 'SCHE4353', VALID_ASSESSOR)
      expect(assessor_gateway.saved_assessor_details).to eq(VALID_ASSESSOR)
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
            first_name: VALID_ASSESSOR[:first_name],
            last_name: VALID_ASSESSOR[:last_name],
            date_of_birth: VALID_ASSESSOR[:date_of_birth]
          }
        )

      add_assessor = described_class.new(schemes_gateway, assessor_gateway)

      expect {
        add_assessor.execute(26, 'SCHE001', VALID_ASSESSOR)
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

    it 'returns false when assessor already exists' do
      expect(
        add_assessor_with_stub_data.execute('25', 'SCHE234950', VALID_ASSESSOR)[
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

    it 'rejects American style dates of birth' do
      assessor = VALID_ASSESSOR.dup
      assessor[:date_of_birth] = '12/20/1990'

      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE93452', assessor)
      }.to raise_exception(
        UseCase::AddAssessor::InvalidAssessorDetailsException
      )
    end

    it 'rejects UK style dates of birth with slashes' do
      assessor = VALID_ASSESSOR.dup
      assessor[:date_of_birth] = '10/12/1990'

      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE93452', assessor)
      }.to raise_exception(
        UseCase::AddAssessor::InvalidAssessorDetailsException
      )
    end

    it 'rejects dates that arent dates at all' do
      assessor = VALID_ASSESSOR.dup
      assessor[:date_of_birth] = '55555555555'

      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE93452', assessor)
      }.to raise_exception(
        UseCase::AddAssessor::InvalidAssessorDetailsException
      )
    end

    it 'rejects dates that are YYYY-DD-MM' do
      assessor = VALID_ASSESSOR.dup
      assessor[:date_of_birth] = '1990-30-07'

      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE93452', assessor)
      }.to raise_exception(
        UseCase::AddAssessor::InvalidAssessorDetailsException
      )
    end

    it 'rejects first names that arent strings' do
      assessor = VALID_ASSESSOR.dup
      assessor[:first_name] = -76

      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE2736', assessor)
      }.to raise_exception(
        UseCase::AddAssessor::InvalidAssessorDetailsException
      )
    end

    it 'rejects last names that arent strings' do
      assessor = VALID_ASSESSOR.dup
      assessor[:last_name] = 24_523

      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE2736', assessor)
      }.to raise_exception(
        UseCase::AddAssessor::InvalidAssessorDetailsException
      )
    end

    it 'rejects middle names that arent strings' do
      assessor = VALID_ASSESSOR.dup
      assessor[:middle_names] = %w[hello]

      expect {
        add_assessor_with_stub_data.execute('25', 'SCHE2736', assessor)
      }.to raise_exception(
        UseCase::AddAssessor::InvalidAssessorDetailsException
      )
    end
  end
end
