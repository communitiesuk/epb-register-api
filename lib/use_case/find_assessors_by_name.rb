module UseCase
  class FindAssessorsByName
    class TooManyResults < Exception; end

    def initialize(assessor_gateway, schemes_gateway)
      @assessor_gateway = assessor_gateway
      @schemes_gateway = schemes_gateway
    end

    def execute(name)
      schemes = []

      @schemes_gateway.all.each do |scheme|
        schemes[scheme[:scheme_id]] = scheme
      end

      result = []

      @assessor_gateway.search_by(name).each do |assessor|
        scheme = schemes[assessor[:registered_by]]
        assessor[:registered_by] = scheme
        result.push(assessor)
      end
      { 'results': result, 'searchName': name }
    rescue Gateway::AssessorsGateway::TooManyResults
      raise TooManyResults
    end
  end
end
