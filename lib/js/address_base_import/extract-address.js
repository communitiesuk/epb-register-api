const isCertifiableAddress = require('./filter-by-classification')

function extractAddress (addressBaseEntry) {
  if (!isCertifiableAddress(addressBaseEntry) && addressBaseEntry.CHANGE_TYPE === 'I') {
    return null
  }

  const usesDeliveryPoint = addressBaseEntry.CLASS.startsWith('R') && addressBaseEntry.UDPRN
  // const addressType = usesDeliveryPoint ? 'Delivery Point' : 'Geographic'

  return usesDeliveryPoint ? createDeliveryPointAddress(addressBaseEntry) : createGeographicAddress(addressBaseEntry)
}

function createGeographicAddress (addressBaseEntry) {
  const uprn = addressBaseEntry.UPRN

  let lines = []

  // If there is a SAO_text value, it should appear on a separate line above the PAO_text line (or the pao number/range + street line where there is no PAO_text value).
  // If there is a SAO_text value, it should always appear on its own line.
  lines.push(addressBaseEntry.SAO_TEXT)

  let street = ''

  // If there is a PAO_text value, it should always appear on the line above the street name (or on the line above the <pao number string> + <street name> where there is a PAO number/range).
  if (addressBaseEntry.PAO_TEXT !== '') {
    const line = []
    if (['SAO_START_NUMBER', 'SAO_START_SUFFIX', 'SAO_END_NUMBER', 'SAO_END_SUFFIX'].some(code => addressBaseEntry[code] !== '')) {
      line.push([
        [
          addressBaseEntry.SAO_START_NUMBER,
          addressBaseEntry.SAO_START_SUFFIX
        ].join(''),
        [
          addressBaseEntry.SAO_END_NUMBER,
          addressBaseEntry.SAO_END_SUFFIX
        ].join('')
      ].filter(x => x !== '').join('-'))
    }
    line.push(addressBaseEntry.PAO_TEXT)
    lines.push(line.filter(x => x !== '').join(' '))
  } else if (['SAO_START_NUMBER', 'SAO_START_SUFFIX', 'SAO_END_NUMBER', 'SAO_END_SUFFIX'].some(code => addressBaseEntry[code] !== '')) {
    street = [
      [
        addressBaseEntry.SAO_START_NUMBER,
        addressBaseEntry.SAO_START_SUFFIX
      ].join(''),
      [
        addressBaseEntry.SAO_END_NUMBER,
        addressBaseEntry.SAO_END_SUFFIX
      ].join('')
    ].filter(x => x !== '').join('-')
  }

  // Generally, if there is a PAO number/range string, it should appear on the same line as the street
  if (['PAO_START_NUMBER', 'PAO_START_SUFFIX', 'PAO_END_NUMBER', 'PAO_END_SUFFIX'].some(code => addressBaseEntry[code] !== '')) {
    const pao = [
      [
        addressBaseEntry.PAO_START_NUMBER,
        addressBaseEntry.PAO_START_SUFFIX
      ].join(''),
      [
        addressBaseEntry.PAO_END_NUMBER,
        addressBaseEntry.PAO_END_SUFFIX
      ].join('')
    ].filter(x => x !== '').join('-')
    street = [street, pao].filter(x => x !== '').join(' ')
  }

  lines.push(
    [street, addressBaseEntry.STREET_DESCRIPTION].filter(x => x !== '').join(' ')
  )

  // The locality name (if present) should appear on a separate line beneath the street description,
  lines.push(addressBaseEntry.LOCALITY)

  // followed by the town name on the line below it. If there is no locality name, the town name should appear alone on the line beneath the street description.
  if (addressBaseEntry.LOCALITY !== addressBaseEntry.TOWN_NAME) {
    lines.push(addressBaseEntry.TOWN_NAME)
  }

  lines = lines.filter(x => x !== '')

  // Finally, the postcode locator, if present, should be inserted on the final line of the address.
  const postcode = (addressBaseEntry.POSTCODE) ? addressBaseEntry.POSTCODE : addressBaseEntry.POSTCODE_LOCATOR

  const town = addressBaseEntry.TOWN_NAME

  if (lines[lines.length - 1] === town) {
    lines.pop()
  }

  return {
    uprn,
    postcode,
    address_line1: lines[0] ?? null,
    address_line2: lines[1] ?? null,
    address_line3: lines[2] ?? null,
    address_line4: lines[3] ?? null,
    town,
    country_code: addressBaseEntry.COUNTRY,
    classification_code: addressBaseEntry.CLASS,
    address_type: 'Geographic'
  }
}

function createDeliveryPointAddress (addressBaseEntry) {
  const uprn = addressBaseEntry.UPRN

  let lines = [
    'DEPARTMENT_NAME',
    'RM_ORGANISATION_NAME',
    'SUB_BUILDING_NAME',
    'BUILDING_NAME',
    'BUILDING_NUMBER',
    'PO_BOX_NUMBER',
    'DEPENDENT_THOROUGHFARE',
    'THOROUGHFARE',
    'DOUBLE_DEPENDENT_LOCALITY',
    'DEPENDENT_LOCALITY'
  ].map(key => addressBaseEntry[key]).filter(x => x)

  lines = combineStreetLine(lines)

  if (lines.length >= 5) {
    lines = compactExcessLines(lines)
  }

  const postcode = addressBaseEntry.POSTCODE

  const town = addressBaseEntry.POST_TOWN

  return {
    uprn,
    postcode,
    address_line1: lines[0] ?? null,
    address_line2: lines[1] ?? null,
    address_line3: lines[2] ?? null,
    address_line4: lines[3] ?? null,
    town,
    country_code: addressBaseEntry.COUNTRY,
    classification_code: addressBaseEntry.CLASS,
    address_type: 'Delivery Point'
  }
}

function compactExcessLines (lines) {
  return lines.slice(0, 3).concat([lines.slice(3).join(', ')])
}

function combineStreetLine (lines) {
  return lines.reduce(
    (carry, val) => {
      if (carry.length > 0 && carry.slice(-1)[0].toString().match(/^\d+[A-Z]?$/)) {
        return carry.slice(0, -1).concat([[carry.slice(-1)[0].toString(), val].join(' ')])
      } else {
        return carry.concat([val])
      }
    },
    []
  )
}

module.exports = extractAddress
