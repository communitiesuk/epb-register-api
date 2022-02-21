const readline = require('readline')
const { Command } = require('commander')
const request = require('request')
const unzipper = require('unzipper')
const csv = require('csv-stream')
const extractAddress = require('../../js/address_base_import/extract-address')
const {
  insertAddressBaseBatch, setUpTempAddressTable, storedVersion, dropLegacyTable, swapInNewVersion, endPool
} = require('../../js/address_base_import/database')
const { newerVersions, latestVersion, downloadFileUrlForVersionUrl } = require('../../js/address_base_import/os-downloads-api')

const program = new Command()

program
  .option('-i, --interactive', 'Interactively give the choice to continue with an action')
  .option('-v, --verbose', 'Show verbose output')
  .action(updateAction)

program.parse()

const start = new Date()

const fileRegex = /AddressBasePlus.*.csv/
const pathRegex = new RegExp(`data\\/${fileRegex.source}`)

const bufferSize = 2_000

async function updateAction ({ interactive, verbose }) {
  output(osLogo(), 'EPBR AddressBase Plus update script', '')

  try {
    const currentVersion = await storedVersion()

    if (currentVersion) {
      output(`The current stored version is '${currentVersion}'.`)
    } else {
      output('There is no version of AddressBase stored currently.')
    }

    const versionsToUpdate = currentVersion
      ? await newerVersions(currentVersion)
      : [await latestVersion()]

    if (versionsToUpdate.length === 0) {
      console.log('There are no new versions to update to at this time.')
      return
    }

    const newVersion = versionsToUpdate.slice(-1)[0]

    console.log(`Action: update to version '${newVersion.productVersion}'.`)

    if (!(await confirm('Continue with this operation?'))) {
      output('Not going ahead. Bye!')
      return
    } else {
      output('Going ahead with it 🤖')
    }

    await setUpTempAddressTable()
    await dropLegacyTable()

    try {
      const csvFiles = await [newVersion.gbUrl, newVersion.islandsUrl].reduce(
        async (carry, downloadUrl) => {
          const carried = await carry
          let directory
          const zipUrl = await downloadFileUrlForVersionUrl(downloadUrl)
          try {
            directory = await fetchDirectory(zipUrl)
          } catch (e) {
            console.error('Could not resolve the URL')
            throw e
          }
          return carried.concat(
            directory.files
              .filter(entry => entry.path.match(pathRegex))
              .map(entry => ({
                file: fileFromPath(entry.path),
                zipUrl: zipUrl
              }))
          )
        },
        Promise.resolve([])
      )

      await writeFiles(csvFiles)
    } catch (e) {
      console.error('Process failed:', e)
    }
  } finally {
    await endPool()
  }

  async function writeFiles (files) {
    const buffer = []

    try {
      return writeCsv(files)
    } catch (e) {
      console.error(e)
      throw e
    }

    async function flushToDb () {
      const batch = buffer.splice(0, buffer.length)
      await insertAddressBaseBatch(batch)
    }

    async function writeCsv (files) {
      const file = files[0]
      const readStream = await readStreamForFile(file)

      output(`starting to read ${file.file} into table`)

      const csvStream = csv.createStream({ columns: addressBaseHeaders(), enclosedChar: '"' })

      readStream
        .on('error', err => {
          console.error(err)
        })
        .on('end', async () => {
          await flushToDb()
          output(`ended reading ${file.file}`)
          const remainingFiles = files.filter(remainingFile => fileFromPath(file.file) !== fileFromPath(remainingFile.file))
          if (remainingFiles.length > 0) {
            readStream.destroy()
            setTimeout(writeCsv, 5000, remainingFiles)
          } else {
            await swapInNewVersion(newVersion.productVersion)
            console.log(`Completed updating to '${newVersion.productVersion}' in ${Math.round(((new Date()) - start) / 1000)}s.`)
          }
        })
        .pipe(csvStream)
        .on('data', data => {
          const address = extractAddress(data)
          if (!address) {
            return
          }
          buffer.push(address)
          if (buffer.length === bufferSize) {
            flushToDb()
          }
        })
        .on('error', err => {
          console.error(err)
        })
    }
  }

  function fetchDirectory (zipUrl) {
    return unzipper.Open.url(
      request,
      {
        url: zipUrl,
        callback: (_error, _response, _body) => {
          // just ignore any error as they are likely connection resets at the beginning or end of a file
        }
      }
    )
  }

  async function readStreamForFile ({ file, zipUrl }) {
    const directory = await fetchDirectory(zipUrl)
    const matchedFiles = directory.files.filter(entry => entry.path.includes(file))
    return matchedFiles[0].stream()
  }

  function fileFromPath (path) {
    return path.split('/').slice(-1)[0]
  }

  function output (...messages) {
    if (verbose) {
      messages.forEach(message => console.log(message))
    }
  }

  async function confirm (question) {
    if (!interactive) {
      return true
    }

    const rl = readline.createInterface({ input: process.stdin, output: process.stdout })
    const answer = await new Promise(resolve => rl.question(`${question} (Y/N) `, resolve))
    rl.close()

    return answer.match(/^Y/i)
  }
}

function addressBaseHeaders () {
  return [
    'UPRN',
    'UDPRN',
    'CHANGE_TYPE',
    'STATE',
    'STATE_DATE',
    'CLASS',
    'PARENT_UPRN',
    'X_COORDINATE',
    'Y_COORDINATE',
    'LATITUDE',
    'LONGITUDE',
    'RPC',
    'LOCAL_CUSTODIAN_CODE',
    'COUNTRY',
    'LA_START_DATE',
    'LAST_UPDATE_DATE',
    'ENTRY_DATE',
    'RM_ORGANISATION_NAME',
    'LA_ORGANISATION',
    'DEPARTMENT_NAME',
    'LEGAL_NAME',
    'SUB_BUILDING_NAME',
    'BUILDING_NAME',
    'BUILDING_NUMBER',
    'SAO_START_NUMBER',
    'SAO_START_SUFFIX',
    'SAO_END_NUMBER',
    'SAO_END_SUFFIX',
    'SAO_TEXT',
    'ALT_LANGUAGE_SAO_TEXT',
    'PAO_START_NUMBER',
    'PAO_START_SUFFIX',
    'PAO_END_NUMBER',
    'PAO_END_SUFFIX',
    'PAO_TEXT',
    'ALT_LANGUAGE_PAO_TEXT',
    'USRN',
    'USRN_MATCH_INDICATOR',
    'AREA_NAME',
    'LEVEL',
    'OFFICIAL_FLAG',
    'OS_ADDRESS_TOID',
    'OS_ADDRESS_TOID_VERSION',
    'OS_ROADLINK_TOID',
    'OS_ROADLINK_TOID_VERSION',
    'OS_TOPO_TOID',
    'OS_TOPO_TOID_VERSION',
    'VOA_CT_RECORD',
    'VOA_NDR_RECORD',
    'STREET_DESCRIPTION',
    'ALT_LANGUAGE_STREET_DESCRIPTION',
    'DEPENDENT_THOROUGHFARE',
    'THOROUGHFARE',
    'WELSH_DEPENDENT_THOROUGHFARE',
    'WELSH_THOROUGHFARE',
    'DOUBLE_DEPENDENT_LOCALITY',
    'DEPENDENT_LOCALITY',
    'LOCALITY',
    'WELSH_DEPENDENT_LOCALITY',
    'WELSH_DOUBLE_DEPENDENT_LOCALITY',
    'TOWN_NAME',
    'ADMINISTRATIVE_AREA',
    'POST_TOWN',
    'WELSH_POST_TOWN',
    'POSTCODE',
    'POSTCODE_LOCATOR',
    'POSTCODE_TYPE',
    'DELIVERY_POINT_SUFFIX',
    'ADDRESSBASE_POSTAL',
    'PO_BOX_NUMBER',
    'WARD_CODE',
    'PARISH_CODE',
    'RM_START_DATE',
    'MULTI_OCC_COUNT',
    'VOA_NDR_P_DESC_CODE',
    'VOA_NDR_SCAT_CODE',
    'ALT_LANGUAGE'
  ]
}

function osLogo () {
  return `
             .......                   ... ..
         'lk0NWMMMWN0kl'           .lOXWMo okkkd:.
      ;xlxMWMMMMMMMMMMMMKc.      ,k0XMMMMd    .'cxd.       ____          _
    .dMMKdWxWMMMMMMMMMMMKkWK:   lWMMKNMMMd        ;,      / __ \\        | |
   lxxMMNxXkMx,dMMMMWMMKxWMMWl  cd0MWXKNXd               | |  | |_ __ __| |_ __   __ _ _ __   ___ ___
  cW0xMMNxNxMOldWMMOdXOdxMMMMWc .O:dOO0NXd ...           | |  | | '__/ _\` | '_ \\ / _\` | '_ \\ / __/ _ \\
 'NMNxMMXdWd000KWXOkcdNNkMMMMMW, :xlWNOWMd.MX0Kkc.       | |__| | | | (_| | | | | (_| | | | | (_|  __/
 cxOK0MMklMNKKXKOK0kxKKKoWMMMMN: .dxkOOO0c.kKNKXNNo.      \\____/|_|  \\__,_|_| |_|\\__,_|_| |_|\\___\\___|
 xkOMMMN,:MMMMMMOWMMMMMMKxWMMXxo  O0O00KWd.NcXMXOkKk.      _____
 oOOMMWk:cNMMMMMOWMMMMMMMKxKkd0c  :0WWXKKc.KockOdld00.    / ____|
 .dOO0xx;cdWMMM0xkMMMMWKkkocKWX.    .cdO0c.MMKxkolkMMl   | (___  _   _ _ ____   _____ _   _
  ,NWOo0,dd0KKK00OKKKKkdkNWK0O,           .XMMMMNdMMM:    \\___ \\| | | | '__\\ \\ / / _ \\ | | |
   ;NM0d,lXMMMMMMMWKkk0WMMMMN,            .dXMMMWdNMk     ____) | |_| | |   \\ V /  __/ |_| |
    .xWk.lMMMMMMNOOKKkONMMWk. .ko.        .XdNMMMKdl.    |_____/ \\__,_|_|    \\_/ \\___|\\__, |
      .;.dMMMMMNkNMMMMNkl:.    .cxxo;..   .MXxK0kx,                                    __/ |
          ,cdk0lk00kdc,            'lxkxd;.00l.'.                                     |___/

  `
}
