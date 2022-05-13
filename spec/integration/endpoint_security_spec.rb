describe "Integration::EndpointSecurity" do
  include RSpecRegisterApiServiceMixin

  methods_with_no_body = %w[head options]
  controllers_to_ignore = { BaseController: {} }

  controllers_to_test =
    Controller.constants.select do |constant|
      Controller.const_get(constant).is_a? Class
    end

  controllers_to_test =
    controllers_to_test.reject do |constant|
      controllers_to_ignore.include? constant.to_s
    end

  routes_to_test = []

  controllers_to_test.each do |controller|
    route_definitions =
      Controller.const_get(controller).routes.map { |method, routes|
        routes.map { |route| route.first.to_s }.map do |route|
          { verb: method.downcase, path: route }
        end
      }.map(&:first)

    routes_to_test |= route_definitions
  end

  total_route_definitions = 34

  it "has a total of #{total_route_definitions} route definitions to test" do
    expect(routes_to_test.length).to eq total_route_definitions
  end

  routes_to_test.each do |route|
    context "an unauthenticated call to #{route[:verb]} #{route[:path]}" do
      verb = route[:verb]
      path = route[:path]

      let(:controller) { method(verb.to_sym) }
      let(:response) { controller.call(path) }

      it "returns a status of 401" do
        expect(response.status).to be 401
      end

      unless methods_with_no_body.include? verb
        it "returns #{Auth::Errors::TokenMissing} in the body" do
          expect(response.body).to include Auth::Errors::TokenMissing.to_s
        end
      end
    end
  end
end
