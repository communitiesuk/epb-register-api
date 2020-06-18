class RenewableHeatIncentiveGatewayFake
  attr_writer :renewable_heat_incentive

  def initialize
    @renewable_heat_incentive = nil
  end

  def fetch(assessment_id)
    if assessment_id == "123-456"
      {
        "epcRrn": "0000-0000-0000-0000-0000",
        "assessorName": "Jo Bloggs",
        "reportType": "Energy Performance Certificate",
        "inspectionDate": "2020-01-30",
        "lodgementDate": "2020-02-29",
        "dwellingType": "Top-floor flat",
        "postcode": "SW1P 4JA",
        "propertyAgeBand": "D",
        "tenure": "Owner-occupied",
        "totalFloorArea": "123.5 square metres",
        "cavityWallInsulation": false,
        "loftInsulation": true,
        "spaceHeating": "Gas-fired central heating",
        "waterHeating": "Electrical immersion heater",
        "secondaryHeating": "Electric bar heater",
        "energyEfficiency": {
          "currentRating": 64,
          "currentBand": "c",
          "potentialRating": 75,
          "potentialBand": "d",
        },
      }
    end
  end
end
