describe 'Integration::EndpointSecurity' do
  include RSpecAssessorServiceMixin

  controllers_to_ignore = { BaseController: {} }

  methods_with_no_body = %w[head options]

  controllers_to_test =
    Controller.constants.select do |constant|
      Controller.const_get(constant).is_a? Class
    end.select { |constant| not controllers_to_ignore.include? constant.to_s }

  @routes_to_test = []

  controllers_to_test.each do |controller|
    routes =
      Controller.const_get(controller).routes.map do |method, routes|
        routes.map { |route| route.first.to_s }.map do |route|
          { verb: method.downcase, path: route }
        end
      end.map(&:first)

    @routes_to_test |= routes
  end

  @routes_to_test.each do |route|
    context "an unauthenticated call to #{route[:verb]} #{route[:path]}" do
      verb = route[:verb]
      path = route[:path]

      let(:controller) { method(verb.to_sym) }
      let(:response) { response = controller.call(path) }

      it 'returns a status of 401' do
        expect(response.status).to be 401
      end

      unless methods_with_no_body.include? verb
        it "returns #{Auth::Errors::TokenMissing.to_s} in the body" do
          expect(response.body).to include Auth::Errors::TokenMissing.to_s
        end
      end
    end
  end
end
