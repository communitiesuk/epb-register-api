describe Middleware::HeadersPolicy do
  subject(:middleware) { described_class.new(app) }

  context "when the middleware is used on an api response" do
    let(:app) do
      app = double
      allow(app).to receive(:call).and_return([200,
                                               Rack::Headers.new.merge({ "Content-Type" => "application/json", "x-frame-options" => "SAMEORIGIN", "x-xss-protection" => "1; mode=bloc" }),
                                               "some content"])
      app
    end

    it "includes the Strict-Transport-Security header" do
      _, headers, = middleware.call(nil)
      expect(headers["Strict-Transport-Security"]).to eq "max-age=300; includeSubDomains; preload"
    end

    it "the header do not include the deprecated keys 'x-frame-options' and 'x-xss-protection'" do
      _, headers, = middleware.call(nil)
      header_keys = %w[content-type strict-transport-security]
      expect(headers.keys).to eq header_keys
    end
  end
end
