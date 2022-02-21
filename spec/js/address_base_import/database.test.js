const { setUpTempAddressTable, db, disconnectDb, insertAddressBaseBatch, storedVersion, writeVersion } = require('../../../lib/js/address_base_import/database')

const truncateAddressBaseTables = async () => {
  const tables = [
    'address_base',
    'address_base_versions',
    'address_base_legacy'
  ]
  const client = await db()
  return Promise.all(tables.map(table => client.query(`TRUNCATE TABLE ${table}`)))
}

const EXISTING_ENV = process.env

beforeAll(() => {
  jest.resetModules()
  process.env = { ...EXISTING_ENV, DATABASE_URL: `postgresql://postgres${process.env.DOCKER_POSTGRES_PASSWORD ? (':' + process.env.DOCKER_POSTGRES_PASSWORD) : ''}@127.0.0.1/epb_test` }
})

beforeEach(async () => {
  jest.resetModules()
  await setUpTempAddressTable()
  await truncateAddressBaseTables()
})

afterAll(async () => {
  process.env = EXISTING_ENV
  await truncateAddressBaseTables()
  await disconnectDb()
})

describe('when inserting a batch of data', () => {
  it('has written one row of data when insertAddressBaseBatch is given a batch of size one', async done => {
    const batch = [{
      uprn: '12345678',
      postcode: 'AB1 1AW',
      address_line1: '6 House Lane',
      address_line2: 'Anyvillage',
      address_line3: null,
      address_line4: null,
      town: 'Anytown',
      classification_code: 'RD06',
      address_type: 'Delivery point'
    }]
    await insertAddressBaseBatch(batch)

    const query = 'SELECT * FROM address_base_tmp WHERE uprn=\'12345678\''
    const result = await (await db()).query(query)

    expect(result.rows).toEqual(batch)
    done()
  })
})

describe('when getting the stored version', () => {
  it('returns null if there is no stored version', async done => {
    expect(await storedVersion()).toBeNull()
    done()
  })

  it('returns the version name for the newest version in the table if there are versions present', async (done) => {
    const insert = 'INSERT INTO address_base_versions (version_name, version_number, created_at) VALUES (\'E89 December 2021 Update\', 89, \'2021-12-06 12:00:00\'), (\'E90 January 2022 Update\', 90, \'2022-01-14 13:00:30\')'
    await (await db()).query(insert)

    expect(await storedVersion()).toEqual('E90 January 2022 Update')
    done()
  })
})

describe('when writing a version', () => {
  it('can be observed to have written it with expected format', async done => {
    const versionString = 'E91 March 2022 Update'
    const versionNumber = 91
    await writeVersion(versionString)

    const selectSql = 'SELECT * FROM address_base_versions WHERE version_name=$1'
    const result = await (await db()).query(selectSql, [versionString])
    expect(result.rows.length).toEqual(1)
    expect(result.rows[0].version_number).toEqual(versionNumber)
    done()
  })
})
