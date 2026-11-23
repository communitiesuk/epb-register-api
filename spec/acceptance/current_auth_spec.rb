# frozen_string_literal: true

describe "Acceptance::CurrentAuth" do
  include RSpecRegisterApiServiceMixin

  context "when using auth_token_has_one_of" do
    let(:app) do
      Class.new(RegisterApiService) do
        get "/test-auth", auth_token_has_one_of: %w[scope] do
          Helper::CurrentAuth.to_json
        end
      end
    end

    it "sets the current auth" do
      header "Authorization", "Bearer #{get_valid_jwt(%w[scope], { foo: 'bar' })}"
      get "/test-auth"

      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body)).to match(
        "auth_token" => {
          "payload" => include(
            "scopes" => %w[scope],
            "sub" => "test-subject",
            "sup" => { "foo" => "bar" },
          ),
        },
      )
    end

    it "clears the current auth" do
      header "Authorization", "Bearer #{get_valid_jwt(%w[scope], { foo: 'bar' })}"
      get "/test-auth"

      expect(Helper::CurrentAuth.auth).to be_nil
    end
  end

  context "when using auth_token_has_all" do
    let(:app) do
      Class.new(RegisterApiService) do
        get "/test-auth", auth_token_has_all: %w[scope] do
          Helper::CurrentAuth.to_json
        end
      end
    end

    it "sets the current auth" do
      header "Authorization", "Bearer #{get_valid_jwt(%w[scope], { foo: 'bar' })}"
      get "/test-auth"

      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body)).to match(
        "auth_token" => {
          "payload" => include(
            "scopes" => %w[scope],
            "sub" => "test-subject",
            "sup" => { "foo" => "bar" },
          ),
        },
      )
    end

    it "clears the current auth" do
      header "Authorization", "Bearer #{get_valid_jwt(%w[scope], { foo: 'bar' })}"
      get "/test-auth"

      expect(Helper::CurrentAuth.auth).to be_nil
    end
  end

  context "without auth" do
    let(:app) do
      Class.new(RegisterApiService) do
        get "/test" do
          Helper::CurrentAuth.to_json
        end
      end
    end

    it "does not set current auth" do
      get "/test"

      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body)).to eq("auth_token" => nil)
      expect(Helper::CurrentAuth.auth).to be_nil
    end

    it "resets current auth before a request" do
      Helper::CurrentAuth.auth = {}
      get "/test"

      expect(last_response.status).to eq 200
      expect(JSON.parse(last_response.body)).to eq("auth_token" => nil)
      expect(Helper::CurrentAuth.auth).to be_nil
    end
  end

  context "with multiple threads" do
    let(:ready) { Queue.new }
    let(:go) { Queue.new }

    let(:app) do
      test_ready = ready
      test_go = go
      Class.new(RegisterApiService) do
        get "/test", auth_token_has_one_of: %w[scope] do
          test_ready << true
          test_go.pop
          Helper::CurrentAuth.to_json
        end
      end
    end

    it "is set in a threadsafe manner" do
      threads = %w[one two].map do |value|
        Thread.new do
          header "Authorization", "Bearer #{get_valid_jwt(%w[scope], { value: })}"
          JSON.parse(get("/test").body)["auth_token"]["payload"]["sup"]["value"]
        end
      end

      ready.pop
      ready.pop
      go << true
      go << true

      threads.each(&:join)

      expect(threads.map(&:value)).to eq %w[one two]
    end
  end
end
