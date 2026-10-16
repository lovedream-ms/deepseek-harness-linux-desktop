# HarmonyOS scaffold

The ArkTS source under `entry/src/main/ets/contract` mirrors the platform
neutral mobile state machine. It intentionally has no endpoint, browser
registration, HTTP transport, token value, or DevEco-specific authentication
implementation.

The future HarmonyOS app should implement only platform adapters around this
contract. It must not copy the Desktop Node/Python/Bash/SSH runtime.
