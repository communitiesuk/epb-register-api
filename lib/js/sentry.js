const Sentry = require('@sentry/node')
require('@sentry/tracing')

function initSentry () {
  Sentry.init({
    environment: process.env.STAGE || 'unknown',
    tracesSampleRate: 1.0
  })
}

function startSentryTransaction (transactionName) {
  const transaction = Sentry.startTransaction({
    op: 'transaction',
    name: transactionName
  })

  Sentry.configureScope(scope => {
    scope.setSpan(transaction)
  })

  return transaction
}

function captureSentryException (e) {
  Sentry.captureException(e)
}

module.exports = { initSentry, startSentryTransaction, captureSentryException }
