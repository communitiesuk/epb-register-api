# frozen_string_literal: true

require "date"

describe "Acceptance::AssessmentSummary" do
  include RSpecRegisterApiServiceMixin

  it "returns 404 for an assessment that doesnt exist" do
    fetch_assessment_summary("000-000", [404])
  end

  context "security" do
    it "rejects a request that is not authenticated" do
      fetch_assessment_summary("123", [401], false)
    end

    it "rejects a request with the wrong scopes" do
      fetch_assessment_summary("124", [403], true, {}, %w[wrong:scope])
    end
  end
end
