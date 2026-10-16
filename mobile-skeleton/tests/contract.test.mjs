import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { join } from 'node:path'
import test from 'node:test'

const root = new URL('../', import.meta.url)
const contract = JSON.parse(
  await readFile(new URL('contract/scnet-mobile-contract.json', root), 'utf8'),
)

const expectedOperations = [
  'login',
  'status',
  'refresh',
  'logout',
  'linkAccount',
  'unlinkAccount',
  'listRegions',
  'listSchedulers',
  'listQueues',
  'submitJob',
  'getJob',
  'cancelJob',
  'listFiles',
  'transferFile',
]

test('keeps the mobile scaffold offline and endpoint-neutral', () => {
  assert.equal(contract.status, 'offline-skeleton')
  assert.equal(contract.network.enabled, false)
  for (const field of [
    'issuer',
    'authorizationEndpoint',
    'tokenEndpoint',
    'revokeEndpoint',
    'jwksEndpoint',
    'clientId',
    'redirectUri',
  ]) {
    assert.equal(contract.network[field], null, `${field} must remain empty`)
  }
  assert.equal(contract.auth.scopeContract, 'pending-formal-scnet-contract')
  assert.deepEqual(Object.keys(contract.operations), expectedOperations)
  for (const operation of expectedOperations) {
    assert.equal(contract.operations[operation].scope, null)
  }
})

test('keeps Android and HarmonyOS source free of endpoint and credential material', async () => {
  const sourceFiles = [
    'android/app/src/main/kotlin/cn/scnet/mobile/skeleton/MobileConnector.kt',
    'harmony/entry/src/main/ets/contract/MobileConnector.ets',
  ]
  const forbidden = /(https?:\/\/|client[_-]?secret\s*[:=]|appsecret\s*[:=]|access[_-]?token\s*[:=]\s*["']|refresh[_-]?token\s*[:=]\s*["']|ak\/sk)/i
  for (const relativePath of sourceFiles) {
    const source = await readFile(join(new URL('../', import.meta.url).pathname, relativePath), 'utf8')
    assert.doesNotMatch(source, forbidden, relativePath)
  }
})

test('exposes only the shared capability states', () => {
  assert.deepEqual(contract.capabilityStates, [
    'supported',
    'unsupported',
    'requires-remote-host',
  ])
  assert.equal(contract.platforms.android.status, 'skeleton')
  assert.equal(contract.platforms.harmonyos.status, 'skeleton')
})
