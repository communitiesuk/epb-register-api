class DomesticEnergyAssessmentsGatewaySpy
  attr_reader :assessment_saved, :assessment_id_saved

  def insert_or_update(assessment_id, assessment_body)
    @assessment_saved = assessment_body
    @assessment_id_saved = assessment_id
  end
end
