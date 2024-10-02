const memoize = require('async-memoize-one')
const pgPkg = require('pg')
const pgPromise = require('pg-promise')
const pgp = pgPromise({})
const { Pool: DbPool } = pgPkg
const { parseVersionNumber } = require('./os-downloads-api')

const pgPool = memoize(createPgPool)
const db = memoize(connect)
const dbP = memoize(createPgp)
const insertAddressBaseColumnSetFn = memoize(insertAddressBaseColumnSet)

async function insertAddressBaseBatch (batch) {
  try {
    const query = pgp.helpers.insert(batch, await insertAddressBaseColumnSetFn())
    await (await dbP()).none(query)
  } catch (e) {
    console.error(e)
  }
}

async function performUpdateBatch (batch) {
  if (batch.length === 0) {
    return
  }
  try {
    const query = pgp.helpers.insert(batch, await insertAddressBaseColumnSetFn()) + onConflictUpdateClause()
    await (await dbP()).none(query)
  } catch (e) {
    console.error(e)
  }
}

function onConflictUpdateClause () {
  return 'ON CONFLICT (uprn) DO UPDATE SET ' + addressBaseColumns().map(column => `${column} = EXCLUDED.${column}`).join(', ')
}

async function performDeleteBatch (batch) {
  if (batch.length === 0) {
    return
  }
  try {
    const deleteSql = 'DELETE FROM address_base_tmp WHERE uprn = ANY($1::varchar[])'
    const client = await connect()
    await client.query(
      deleteSql,
      [batch.map(obj => obj.uprn)]
    )
    client.release()
  } catch (e) {
    console.error(e)
  }
}

function insertAddressBaseColumnSet () {
  return new pgp.helpers.ColumnSet(addressBaseColumns(), { table: 'address_base_tmp' })
}

function addressBaseColumns () {
  return [
    'uprn',
    'postcode',
    'address_line1',
    'address_line2',
    'address_line3',
    'address_line4',
    'town',
    'classification_code',
    'address_type',
    'country_code'
  ]
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
  const sql = 'INSERT INTO address_base_versions (version_name, version_number, created_at) VALUES ($1, $2, NOW()) '
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

async function createEmptyTempAddressTable () {
  return setUpTempAddressTable(false)
}

async function duplicateAddressBaseToTempTable () {
  return setUpTempAddressTable(true)
}

async function setUpTempAddressTable (asCopy) {
  const deleteSql = 'DROP TABLE IF EXISTS address_base_tmp'
  const client = await connect()
  await client.query(deleteSql)
  const createSql = `CREATE TABLE address_base_tmp AS TABLE address_base${asCopy ? '' : ' WITH NO DATA'}`
  await client.query(createSql)
  await ensureTempTableHasPrimaryKey()
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
  return runQuery('CREATE INDEX IF NOT EXISTS index_address_base_tmp_on_postcode ON address_base_tmp (postcode)')
}

async function renameExistingAddressBaseTableToLegacy () {
  await runQuery('ALTER TABLE address_base RENAME TO address_base_legacy')
  return runQuery('ALTER INDEX IF EXISTS index_address_base_on_postcode RENAME TO index_address_base_legacy_on_postcode')
}

async function renameTempTableToAddressBase () {
  await runQuery('ALTER TABLE address_base_tmp RENAME TO address_base')
  return runQuery('ALTER INDEX IF EXISTS index_address_base_tmp_on_postcode RENAME TO index_address_base_on_postcode')
}

async function ensureTempTableHasPrimaryKey () {
  const checkKeyExistenceSql = "SELECT constraint_name FROM information_schema.table_constraints WHERE table_name = 'address_base_tmp' AND constraint_type = 'PRIMARY KEY'"
  const client = await connect()
  try {
    const keyResult = await client.query(checkKeyExistenceSql)
    if (keyResult.rows.length > 0) {
      return
    }
    await client.query('ALTER TABLE address_base_tmp ADD PRIMARY KEY (uprn)')
  } finally {
    client.release()
  }
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
  return { connectionString: process.env.DATABASE_URL }
}

async function disconnectDb () {
  return (await db()).end()
}

async function endPool () {
  return (await pgPool()).end()
}

module.exports = { db, disconnectDb, insertAddressBaseBatch, performUpdateBatch, performDeleteBatch, duplicateAddressBaseToTempTable, createEmptyTempAddressTable, storedVersion, writeVersion, dropLegacyTable, swapInNewVersion, endPool }
