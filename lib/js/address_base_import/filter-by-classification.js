function isCertifiableAddress (address) {
  return isInCertifiableCountry(address) && hasCertifiableClassification(address)
}

function hasCertifiableClassification (address) {
  const classCode = address.CLASS
  if (classCode.length === 0) {
    return true
  }
  switch (classCode[0]) {
    case 'C': // Commercial
      return ![
        'CC10', // Recycling site
        'CC11', // CCTV
        'CL06QS', // Racquet sports facility (tennis court et al)
        'CL09', // Beach hut
        'CR11', // ATM
        'CT01HT', // Heliport / helipad
        'CT02', // Bus shelter
        'CT05', // Marina
        'CT06', // Mooring
        'CT07', // Railway asset
        'CT09', // Transport track / way
        'CT11', // Transport-related architecture
        'CT12', // Overnight lorry park
        'CT13', // Harbour / port / dock / dockyard
        'CU01', // Electricity Sub Station
        'CU02', // Landfill
        'CU11', // Telephone box
        'CU12', // Dam
        'CZ01', // Advertising hoarding
        'CZ02', // Information signage
        'CZ03' // Traffic information signage
      ].some(prefix => classCode.startsWith(prefix))
    case 'L': // Land
      return classCode.startsWith('LB99PI') // Pavilion/Changing Room
    case 'M': // Military
      return true
    case 'O': // Other
      return false
    case 'P': // Parent
      return classCode.startsWith('PP') // Property shell
    case 'R':
      return ![
        'RC', // Car park space
        'RD07', // House boat
        'RG02' // Garage/ lock-up
      ].some(prefix => classCode.startsWith(prefix))
    case 'U': // Unclassified
      return true
    case 'Z':
      return [
        'ZM04', // Castle / historic ruin
        'ZS', // Stately home
        'ZV01', // Cellar
        'ZW99' // Place of worship
      ].some(prefix => classCode.startsWith(prefix))
    default:
      return true
  }
}

function isInCertifiableCountry (address) {
  return !(['S', 'L', 'M'].includes(address.COUNTRY)) // filter out addresses from Scotland, Channel Islands or Isle of Man
}

module.exports = isCertifiableAddress
