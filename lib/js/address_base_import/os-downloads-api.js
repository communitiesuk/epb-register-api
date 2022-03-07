const fetch = require('node-fetch')

const unauthorisedError = 'Access to Ordnance Survey Downloads API not authorised - are you using a current API key?'

async function newerVersions (versionString) {
  try {
    const { gbPackage, islandsPackage } = await availablePackages('COU')
    const newerGbVersions = extractNewerVersions(gbPackage.versions, versionString)
    const newerIslandsVersions = extractNewerVersions(islandsPackage.versions, versionString)
    return newerGbVersions
      .filter(gbVersion => newerIslandsVersions.some(islandVersion => gbVersion.productVersion === islandVersion.productVersion))
      .map(gbVersion => ({
        gbUrl: gbVersion.url,
        islandsUrl: newerIslandsVersions.filter(version => version.productVersion === gbVersion.productVersion)[0].url,
        productVersion: gbVersion.productVersion,
        isDelta: gbVersion.supplyType !== 'Full'
      })
      )
  } catch (e) {
    console.error('Newer versions lookup failed:', e)
    throw e
  }
}

async function latestVersion () {
  try {
    const { gbPackage, islandsPackage } = await availablePackages('FULL')
    const latestGbVersion = gbPackage.versions
      .sort(sortVersions)
      .reverse()
      .find(gbVersion => islandsPackage.versions.some(islandsVersion => gbVersion.productVersion === islandsVersion.productVersion))
    if (!latestGbVersion) {
      return null
    }
    return {
      gbUrl: latestGbVersion.url,
      islandsUrl: islandsPackage.versions.find(islandsVersion => latestGbVersion.productVersion === islandsVersion.productVersion).url,
      productVersion: latestGbVersion.productVersion,
      isDelta: latestGbVersion.supplyType !== 'Full'
    }
  } catch (e) {
    console.error('Latest version lookup failed:', e)
    throw e
  }
}

async function availablePackages (packageType) {
  const response = await fetch(`https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(process.env.OS_DATA_HUB_API_KEY)}`)
  if (response.status === 401) {
    throw new Error(unauthorisedError)
  }
  const data = await response.json()
  return {
    gbPackage: extractPackageWithProductName(data, 'AddressBase Plus', packageType),
    islandsPackage: extractPackageWithProductName(data, 'AddressBase Plus - Islands', packageType)
  }
}

/**
 *
 * @param packagesData
 * @param productName
 * @param packageType This is either 'FULL' or 'COU', and is found within a package name in the OS Data Hub, e.g. 'EPBR - AddressBase Plus (FULL)'
 * @returns array
 */
function extractPackageWithProductName (packagesData, productName, packageType) {
  return packagesData.filter(pkg => isEpbrPackage(pkg) && isPackageType(pkg, packageType) && pkg.productName === productName)[0]
}

/**
 * The EPBR data packages within the OS Data Hub are prefixed with "EPBR" - this check ensures the process does not use other packages that exist on the account.
 *
 * @param packageData
 * @returns boolean
 */
function isEpbrPackage (packageData) {
  return packageData.name.match(/^EPBR/)
}

function isPackageType (packageData, packageType) {
  return packageData.name.match(new RegExp(`(${packageType})`))
}

function parseVersionNumber (versionString) {
  const matches = /^E(\d+)/.exec(versionString)
  if (!matches || matches.length < 2) {
    throw new Error('Unexpected version string format encountered.')
  }
  return +(matches[1])
}

function extractNewerVersions (versions, currentVersionString) {
  return versions
    .filter(version => parseVersionNumber(version.productVersion) > parseVersionNumber(currentVersionString))
    .sort(sortVersions)
}

function sortVersions (first, second) {
  return parseVersionNumber(first.productVersion) - parseVersionNumber(second.productVersion)
}

async function downloadFileUrlForVersionUrl (packageVersionUrl) {
  const response = await fetch(packageVersionUrl)
  switch (response.status) {
    case 401:
      throw new Error(unauthorisedError)
    case 404:
      throw new Error('Received unexpected 404 Not Found for a package version URL.')
    default:
      // fall through
  }
  const versionPayload = await response.json()
  return versionPayload.downloads[0].url
}

module.exports = { newerVersions, latestVersion, parseVersionNumber, downloadFileUrlForVersionUrl }
