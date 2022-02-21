const memoize = require('async-memoize-one')
const pgPkg = require('pg')
const pgPromise = require('pg-promise')
const pgp = pgPromise({})
const { Pool: DbPool } = pgPkg
const { parseVersionNumber } = require('./os-downloads-api')

const pgPool = memoize(createPgPool)
const db = memoize(connect)
const dbP = memoize(createPgp)
const addressBaseColumnSet = memoize(createAddressBaseColumnSet)

async function insertAddressBaseBatch (batch) {
  try {
    const query = pgp.helpers.insert(batch, await addressBaseColumnSet())
    await (await dbP()).none(query)
  } catch (e) {
    console.error(e)
  }
}

function createAddressBaseColumnSet () {
  return new pgp.helpers.ColumnSet([
    'uprn',
    'postcode',
    'address_line1',
    'address_line2',
    'address_line3',
    'address_line4',
    'town',
    'classification_code',
    'address_type'
  ], { table: 'address_base_tmp' })
}

async function storedVersion () {
  const sql = 'SELECT version_name FROM address_base_versions ORDER BY version_number DESC LIMIT 1'
  const client = await connect()
  const result = await client.query(sql)
  client.release()
  if (result.rows.length === 0) {
    return null
  }
  return result.rows[0].version_name
}

async function writeVersion (versionString) {
  const sql = 'INSERT INTO address_base_versions (version_name, version_number, created_at) VALUES ($1, $2, NOW())'
  const client = await connect()
  await client.query(
    sql,
    [
      versionString,
      parseVersionNumber(versionString)
    ]
  )
  client.release()
}

async function setUpTempAddressTable () {
  const deleteSql = 'DROP TABLE IF EXISTS address_base_tmp'
  const client = await connect()
  await client.query(deleteSql)
  const createSql = `CREATE TABLE IF NOT EXISTS address_base_tmp (
                        uprn VARCHAR,
                        postcode VARCHAR,
                        address_line1 VARCHAR,
                        address_line2 VARCHAR,
                        address_line3 VARCHAR,
                        address_line4 VARCHAR,
                        town VARCHAR,
                        classification_code VARCHAR(6),
                        address_type VARCHAR(15),
                        PRIMARY KEY (uprn)
                     )
                     `
  await client.query(createSql)
  client.release()
}

async function swapInNewVersion (versionString) {
  await addPostcodeIndexToTempAddressTable()
  await renameExistingAddressBaseTableToLegacy()
  await renameTempTableToAddressBase()
  await writeVersion(versionString)
}

async function dropLegacyTable () {
  return runQuery('DROP TABLE IF EXISTS address_base_legacy')
}

async function addPostcodeIndexToTempAddressTable () {
  return runQuery('CREATE INDEX IF NOT EXISTS index_address_base_on_postcode ON address_base_tmp (postcode)')
}

async function renameExistingAddressBaseTableToLegacy () {
  return runQuery('ALTER TABLE address_base RENAME TO address_base_legacy')
}

async function renameTempTableToAddressBase () {
  return runQuery('ALTER TABLE address_base_tmp RENAME TO address_base')
}

async function runQuery (sql) {
  const client = await connect()
  await client.query(sql)
  client.release()
}

function createPgPool () {
  return new DbPool(connectionOptions())
}

async function connect () {
  return (await pgPool()).connect()
}

async function createPgp () {
  return pgp(connectionOptions())
}

function connectionOptions () {
  return { connectionString: process.env.DATABASE_URL, ssl: process.env.DATABASE_URL.includes('rds') }
}

async function disconnectDb () {
  return (await db()).end()
}

async function endPool () {
  return (await pgPool()).end()
}

module.exports = { db, disconnectDb, insertAddressBaseBatch, setUpTempAddressTable, storedVersion, writeVersion, dropLegacyTable, swapInNewVersion, endPool }
