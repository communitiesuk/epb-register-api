const {
  isPaas
} = require('../../../lib/js/address_base_import/platform')

const EXISTING_ENV = process.env

beforeAll(() => {
  jest.resetModules()
})

describe('when there is an environment variable available called VCAP_SERVICES', () => {
  beforeEach(() => {
    process.env = { ...EXISTING_ENV, VCAP_SERVICES: '{}' }
  })

  it('reports as being in PaaS', () => {
    expect(isPaas()).toBeTruthy()
  })
})

describe('when there is no environment variable available called VCAP_SERVICES', () => {
  beforeEach(() => {
    const { VCAP_SERVICES: _, ...envMinusVcap } = EXISTING_ENV
    process.env = envMinusVcap
  })

  it('reports as not being in PaaS', () => {
    expect(isPaas()).toBeFalsy()
  })
})

afterAll(() => {
  process.env = EXISTING_ENV
})
