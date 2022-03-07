jest.mock('node-fetch', () => require('fetch-mock-jest').sandbox())
const fetchMock = require('node-fetch')
const { newerVersions, latestVersion, parseVersionNumber, downloadFileUrlForVersionUrl } = require('../../../lib/js/address_base_import/os-downloads-api.js')

const apiKey = process.env.OS_DATA_HUB_API_KEY

afterEach(() => {
  fetchMock.mockReset()
})

describe('when checking which newer versions of the AddressBase data are available', () => {
  test('it gives two versions when there are two available', async () => {
    const existingVersionString = 'E88 October 2021 Update'
    const dataPackages = [
      {
        id: '0040146690',
        name: 'EPBR - AddressBase Plus (FULL)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5668491',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E93 May 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587961',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E92 April 2022 Update',
            format: 'CSV'
          },
          {
            id: '5527646',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5527646?key=${encodeURI(apiKey)}`,
            createdOn: '2021-10-29',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E91 March 2022 Update',
            format: 'CSV'
          },
          {
            id: '5468716',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5468716?key=${encodeURI(apiKey)}`,
            createdOn: '2021-09-16',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'EPBR - AddressBase Plus (FULL)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5668869',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E93 May 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E92 April 2022 Update',
            format: 'CSV'
          },
          {
            id: '5527712',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5527712?key=${encodeURI(apiKey)}`,
            createdOn: '2021-10-29',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E91 March 2022 Update',
            format: 'CSV'
          },
          {
            id: '5469630',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5469630?key=${encodeURI(apiKey)}`,
            createdOn: '2021-09-17',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040146690',
        name: 'EPBR - AddressBase Plus (COU)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5668491',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Change Only Update',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587961',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Change Only Update',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          },
          {
            id: '5527646',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5527646?key=${encodeURI(apiKey)}`,
            createdOn: '2021-10-29',
            reason: 'UPDATE',
            supplyType: 'Change Only Update',
            productVersion: 'E88 October 2021 Update',
            format: 'CSV'
          },
          {
            id: '5468716',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5468716?key=${encodeURI(apiKey)}`,
            createdOn: '2021-09-16',
            reason: 'INITIAL',
            supplyType: 'Full',
            productVersion: 'E87 September 2021 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'EPBR - AddressBase Plus (COU)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5668869',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Change Only Update',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Change Only Update',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          },
          {
            id: '5527712',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5527712?key=${encodeURI(apiKey)}`,
            createdOn: '2021-10-29',
            reason: 'UPDATE',
            supplyType: 'Change Only Update',
            productVersion: 'E88 October 2021 Update',
            format: 'CSV'
          },
          {
            id: '5469630',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5469630?key=${encodeURI(apiKey)}`,
            createdOn: '2021-09-17',
            reason: 'INITIAL',
            supplyType: 'Full',
            productVersion: 'E87 September 2021 Update',
            format: 'CSV'
          }
        ]
      }
    ]

    fetchMock
      .get(
        `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`,
        dataPackages
      )

    expect(await newerVersions(existingVersionString)).toEqual([
      {
        gbUrl: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
        islandsUrl: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
        productVersion: 'E89 December 2021 Update',
        isDelta: true
      },
      {
        gbUrl: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
        islandsUrl: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
        productVersion: 'E90 January 2022 Update',
        isDelta: true
      }
    ])
  })

  test('it gives one version when there are two GB versions but one Islands version', async () => {
    const existingVersionString = 'E88 October 2021 Update'
    const dataPackages = [
      {
        id: '0040146690',
        name: 'EPBR - AddressBase Plus (COU)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5668491',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587961',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          },
          {
            id: '5527646',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5527646?key=${encodeURI(apiKey)}`,
            createdOn: '2021-10-29',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E88 October 2021 Update',
            format: 'CSV'
          },
          {
            id: '5468716',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5468716?key=${encodeURI(apiKey)}`,
            createdOn: '2021-09-16',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E87 September 2021 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'EPBR - AddressBase Plus (COU)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          },
          {
            id: '5527712',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5527712?key=${encodeURI(apiKey)}`,
            createdOn: '2021-10-29',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E88 October 2021 Update',
            format: 'CSV'
          },
          {
            id: '5469630',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5469630?key=${encodeURI(apiKey)}`,
            createdOn: '2021-09-17',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E87 September 2021 Update',
            format: 'CSV'
          }
        ]
      }
    ]

    fetchMock
      .get(
        `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`,
        dataPackages
      )

    expect(await newerVersions(existingVersionString)).toEqual([
      {
        gbUrl: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
        islandsUrl: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
        productVersion: 'E89 December 2021 Update',
        isDelta: false
      }
    ])
  })

  test('it gives one version when there is one GB version but two Islands versions', async () => {
    const existingVersionString = 'E88 October 2021 Update'
    const dataPackages = [
      {
        id: '0040146690',
        name: 'EPBR - AddressBase Plus (COU)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5587961',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          },
          {
            id: '5527646',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5527646?key=${encodeURI(apiKey)}`,
            createdOn: '2021-10-29',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E88 October 2021 Update',
            format: 'CSV'
          },
          {
            id: '5468716',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5468716?key=${encodeURI(apiKey)}`,
            createdOn: '2021-09-16',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E87 September 2021 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'EPBR - AddressBase Plus (COU)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5668869',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          },
          {
            id: '5527712',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5527712?key=${encodeURI(apiKey)}`,
            createdOn: '2021-10-29',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E88 October 2021 Update',
            format: 'CSV'
          },
          {
            id: '5469630',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5469630?key=${encodeURI(apiKey)}`,
            createdOn: '2021-09-17',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E87 September 2021 Update',
            format: 'CSV'
          }
        ]
      }
    ]

    fetchMock
      .get(
        `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`,
        dataPackages
      )

    expect(await newerVersions(existingVersionString)).toEqual([
      {
        gbUrl: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
        islandsUrl: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
        productVersion: 'E89 December 2021 Update',
        isDelta: false
      }
    ])
  })

  test('it gives no newer versions when the current version string is the latest', async () => {
    const existingVersionString = 'E90 January 2022 Update'
    const dataPackages = [
      {
        id: '0040146690',
        name: 'EPBR - AddressBase Plus (COU)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5668491',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587961',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'EPBR - AddressBase Plus (COU)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5668869',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          }
        ]
      }
    ]

    fetchMock
      .get(
        `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`,
        dataPackages
      )

    expect(await newerVersions(existingVersionString)).toEqual([])
  })

  test('it throws a suitable error when the API sends a 401', () => {
    jest.spyOn(console, 'error').mockImplementation(() => {}) // silence the console.error call

    const existingVersionString = 'E90 January 2022 Update'

    fetchMock
      .get(
        {
          url: `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`
        },
        {
          body: {
            message: 'Invalid APIKey'
          },
          status: 401
        }
      )

    expect(newerVersions(existingVersionString)).rejects.toEqual(new Error('Access to Ordnance Survey Downloads API not authorised - are you using a current API key?'))
  })
})

describe('when fetching the latest available version of the AddressBase Plus data (including Islands)', () => {
  it('returns the version object if there is a latest one available for both GB and Islands', async () => {
    const dataPackages = [
      {
        id: '0040146690',
        name: 'EPBR - AddressBase Plus (FULL)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5668491',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587961',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'EPBR - AddressBase Plus (FULL)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5668869',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          }
        ]
      }
    ]

    fetchMock
      .get(
        `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`,
        dataPackages
      )

    expect(await latestVersion()).toEqual({
      gbUrl: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
      islandsUrl: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
      productVersion: 'E90 January 2022 Update',
      isDelta: false
    })
  })

  it('fetches the EPBR packages out if there are other AddressBase Plus packages', async () => {
    const dataPackages = [
      {
        id: '0040146690',
        name: 'Some other team',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5668491',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E92 April 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587961',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E91 March 2022 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'Some other team',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5668869',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E92 April 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E91 March 2021 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040146690',
        name: 'EPBR - AddressBase Plus (FULL)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5668491',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587961',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5587961?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'EPBR - AddressBase Plus (FULL)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5668869',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          },
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          }
        ]
      }
    ]

    fetchMock
      .get(
        `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`,
        dataPackages
      )

    expect(await latestVersion()).toEqual({
      gbUrl: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
      islandsUrl: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
      productVersion: 'E90 January 2022 Update',
      isDelta: false
    })
  })

  it('returns null when there is no common latest version available', async () => {
    const dataPackages = [
      {
        id: '0040146690',
        name: 'EPBR - AddressBase Plus (FULL)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040146690?key=${encodeURI(apiKey)}`,
        createdOn: '2021-01-08',
        productId: 'ABFLATSLA',
        productName: 'AddressBase Plus',
        versions: [
          {
            id: '5668491',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040146690/versions/5668491?key=${encodeURI(apiKey)}`,
            createdOn: '2022-01-27',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E90 January 2022 Update',
            format: 'CSV'
          }
        ]
      },
      {
        id: '0040143634',
        name: 'EPBR - AddressBase Plus (FULL)',
        url: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
        createdOn: '2020-08-13',
        productId: 'ABPLISSLA',
        productName: 'AddressBase Plus - Islands',
        versions: [
          {
            id: '5587319',
            url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
            createdOn: '2021-12-09',
            reason: 'UPDATE',
            supplyType: 'Full',
            productVersion: 'E89 December 2021 Update',
            format: 'CSV'
          }
        ]
      }
    ]

    fetchMock
      .get(
        `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`,
        dataPackages
      )

    expect(await latestVersion()).toBeNull()
  })

  it('throws a suitable error if the data packages respond with a 401', () => {
    fetchMock
      .get(
        {
          url: `https://api.os.uk/downloads/v1/dataPackages?key=${encodeURI(apiKey)}`
        },
        {
          body: {
            message: 'Invalid APIKey'
          },
          status: 401
        }
      )

    expect(latestVersion()).rejects.toEqual(new Error('Access to Ordnance Survey Downloads API not authorised - are you using a current API key?'))
  })
})

describe('when parsing out the version number from the product string', () => {
  it('parses correctly from a two digit number', () => {
    expect(parseVersionNumber('E89 December 2021 Update')).toBe(89)
  })

  it('parses correctly from a three digit number', () => {
    expect(parseVersionNumber('E101 February 2023')).toBe(101)
  })

  it('throws when a version string is in an unexpected format', () => {
    expect(() => parseVersionNumber('New Unexpected Format June 2525')).toThrow('Unexpected version string format encountered.')
  })
})

describe('when getting the file download URL for a specific package version', () => {
  it('correctly picks the download file from the version package payload and returns it', async () => {
    const versionPayload = {
      id: '5668869',
      url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
      createdOn: '2022-01-27',
      reason: 'UPDATE',
      supplyType: 'Full',
      productVersion: 'E90 January 2022 Update',
      format: 'CSV',
      dataPackageUrl: `https://api.os.uk/downloads/v1/dataPackages/0040143634?key=${encodeURI(apiKey)}`,
      previousVersionUrl: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5587319?key=${encodeURI(apiKey)}`,
      downloads: [
        {
          fileName: 'ABPLIS_CSV.zip',
          url: `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869/downloads?fileName=ABPLIS_CSV.zip&key=${encodeURI(apiKey)}`,
          size: 92599166
        }
      ]
    }

    fetchMock
      .get(
        `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`,
        versionPayload
      )

    expect(await downloadFileUrlForVersionUrl(`https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`))
      .toEqual(`https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869/downloads?fileName=ABPLIS_CSV.zip&key=${encodeURI(apiKey)}`)
  })

  it('throws a suitable error when the package version URL sends a 401', () => {
    const packageVersionUrl = `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`

    fetchMock
      .get(
        {
          url: packageVersionUrl
        },
        {
          body: {
            message: 'Invalid APIKey'
          },
          status: 401
        }
      )

    expect(downloadFileUrlForVersionUrl(packageVersionUrl)).rejects.toEqual(new Error('Access to Ordnance Survey Downloads API not authorised - are you using a current API key?'))
  })

  it('throws a suitable error when the package version URL sends a 404', () => {
    const packageVersionUrl = `https://api.os.uk/downloads/v1/dataPackages/0040143634/versions/5668869?key=${encodeURI(apiKey)}`

    fetchMock
      .get(
        {
          url: packageVersionUrl
        },
        {
          body: {
            message: 'string',
            dataPackagesUrl: 'string',
            downloadCatalogueUrl: 'string',
            productUrl: 'string',
            productDownloadsUrl: 'string'
          },
          status: 404
        }
      )

    expect(downloadFileUrlForVersionUrl(packageVersionUrl)).rejects.toEqual(new Error('Received unexpected 404 Not Found for a package version URL.'))
  })
})
