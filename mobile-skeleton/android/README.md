# Android scaffold

The Kotlin source under `app/src/main/kotlin` defines the mobile connector
boundary and an offline authentication state machine. It is deliberately
independent of Android UI, AppAuth, HTTP clients, and real credential stores
until the SCNet contract is formally supplied.

This is a source scaffold, not an APK project yet. A future Android repository
can consume the same contract manifest and conformance tests without copying
Desktop shell, Python, Bash, SSH, or Notebook execution code.
