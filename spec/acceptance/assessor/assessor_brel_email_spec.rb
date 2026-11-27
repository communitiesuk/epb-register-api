describe "Searching for an assessor brel email" do
  include RSpecRegisterApiServiceMixin

  it_behaves_like "when checking an endpoint requires bearer token access",
                  end_point: "assessors/xxx/brel-email",
                  scopes: %w[assessor:brel-email]

  describe "GET /assessors/{schemeAssessorId}/brel-email" do
    context "with a qualified assessor" do
      it "returns the email" do
        scheme_id = add_scheme_and_get_id
        add_super_assessor(scheme_id:)

        response = fetch_assessor_brel_email(assessor_id: "SPEC000000")
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq("email" => "person@person.com")
      end
    end

    context "when the assessor is unqualified" do
      it "returns an empty hash" do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id:,
          assessor_id: "TEST000001",
          body: AssessorStub.new.fetch_request_body,
        )

        response = fetch_assessor_brel_email(assessor_id: "TEST000001")
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context "with a qualified assessor with a slash in the name" do
      it "returns the email" do
        scheme_id = add_scheme_and_get_id
        add_assessor(
          scheme_id:,
          assessor_id: "TEST%2F000001",
          body: AssessorStub.new.fetch_request_body(email: "email@example.com", domestic_sap: "ACTIVE"),
        )

        response = fetch_assessor_brel_email(assessor_id: "TEST%2F000001")
        expect(JSON.parse(response.body)).to eq("email" => "email@example.com")
      end
    end

    context "when the assessor is not found" do
      it "returns an empty hash" do
        response = fetch_assessor_brel_email(assessor_id: "xxxx")
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)).to eq({})
      end
    end
  end
end
