RSpec.describe "Maintenance mode" do
  include RSpecRegisterApiServiceMixin

  ignored_controllers = { BaseController: {} }.freeze
  controllers_to_test = Controller.constants.select { |constant| Controller.const_get(constant).is_a?(Class) }.reject do |constant|
    ignored_controllers.include?(constant.to_s)
  end

  routes_to_test = controllers_to_test.map { |controller|
    Controller.const_get(controller).routes.map do |method, routes|
      routes.map { |route| route.first.to_s }.map do |route|
        { verb: method.downcase, path: route } unless method.casecmp("head").zero?
      end
    end
  }.flatten.compact

  context "when maintenance mode is OFF" do
    before { Helper::Toggles.set_feature("register-api-maintenance-mode", false) }

    it "allows all requests" do
      routes_to_test.each do |route|
        controller = method(route[:verb].to_sym)
        response = controller.call(route[:path])

        expect(response.status).not_to be 503
      end
    end
  end

  context "when maintenance mode is ON" do
    before { Helper::Toggles.set_feature("register-api-maintenance-mode", true) }

    after { Helper::Toggles.set_feature("register-api-maintenance-mode", false) }

    it "allows request to the /healthcheck endpoint" do
      response = get "/healthcheck"

      expect(response.status).to be 200
    end

    it "rejects all requests (except /healthcheck)" do
      routes_to_test.each do |route|
        controller = method(route[:verb].to_sym)
        response = controller.call(route[:path])

        expect(response.status).to be 503
        expect(JSON.parse(response.body, symbolize_names: true)[:errors]).to eq(
          [{ code: "SERVICE_UNAVAILABLE", title: "The service is currently under maintenance" }],
        )
      end
    end
  end
end
