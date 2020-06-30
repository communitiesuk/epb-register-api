class RelatedAssessmentsGatewayStub
  def fetch_related_assessments(*)
    [
      {
        "assessmentExpiryDate" => "2016-05-04",
        "assessmentId" => "1234-3453-6245-2473-5623",
        "assessmentStatus" => "EXPIRED",
        "assessmentType" => "SAP",
      },
    ]
  end
end
