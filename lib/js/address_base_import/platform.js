const isPaas = () => typeof process.env.VCAP_SERVICES !== 'undefined'

module.exports = { isPaas }
