# Mobile skeleton

This directory is a contract-first Android and HarmonyOS scaffold. It is not
part of the Linux Desktop package and does not perform network authentication.

The scaffold intentionally contains:

- the connector operation and capability manifest shared by mobile adapters;
- an Android/Kotlin state-machine interface;
- a HarmonyOS/ArkTS state-machine interface;
- offline conformance tests that reject endpoint and credential material.

The scaffold intentionally does not contain:

- an issuer, authorization endpoint, token endpoint, redirect URI, client ID,
  client secret, access token, refresh token, AK/SK, or private host;
- a real HTTP transport;
- a production browser callback registration;
- Node, Python, Bash, SSH, or Desktop runtime code.

The source contract is the published `dsh-scnet@0.6.13` connector contract.
Changes to that contract must still begin at canonical `scnet-hpc`, then flow
through `dsh-scnet` before mobile adapters consume them.

## Offline check

```sh
node --test mobile-skeleton/tests/*.test.mjs
```

The local environment used for this scaffold does not include an Android SDK,
Gradle, Java, or the HarmonyOS DevEco toolchain. APK/HAP builds are therefore
intentionally deferred until those toolchains and platform repositories are
available.
