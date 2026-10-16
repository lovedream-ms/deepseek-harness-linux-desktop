package cn.scnet.mobile.skeleton

enum class AuthState {
    SIGNED_OUT,
    AWAITING_BROWSER,
    CALLBACK_RECEIVED,
    AUTHENTICATED,
    FAILED,
}

enum class CapabilityState {
    SUPPORTED,
    UNSUPPORTED,
    REQUIRES_REMOTE_HOST,
}

data class LoginPlan(
    val networkEnabled: Boolean = false,
    val endpointConfigured: Boolean = false,
    val requiresFormalContract: Boolean = true,
)

data class TokenSnapshot(
    val hasAccessToken: Boolean,
    val hasRefreshToken: Boolean,
    val expiresAtEpochSeconds: Long?,
)

interface SecureTokenStore {
    suspend fun read(): TokenSnapshot?
    suspend fun write(snapshot: TokenSnapshot)
    suspend fun clear()
}

interface BrowserAuthSession {
    suspend fun open(plan: LoginPlan)
}

interface ConnectorTransport {
    suspend fun execute(operation: String, request: Map<String, Any?> = emptyMap()): Map<String, Any?>
}

class OfflineMobileConnector(
    private val tokenStore: SecureTokenStore,
) {
    private var currentState = AuthState.SIGNED_OUT

    fun state(): AuthState = currentState

    fun beginLogin(): LoginPlan {
        check(currentState == AuthState.SIGNED_OUT || currentState == AuthState.FAILED) {
            "login is already in progress"
        }
        currentState = AuthState.AWAITING_BROWSER
        return LoginPlan()
    }

    fun receiveCallbackForTest() {
        check(currentState == AuthState.AWAITING_BROWSER) {
            "callback is not expected in the current state"
        }
        currentState = AuthState.CALLBACK_RECEIVED
    }

    fun markAuthenticatedForTest() {
        check(currentState == AuthState.CALLBACK_RECEIVED) {
            "authentication result is not expected in the current state"
        }
        currentState = AuthState.AUTHENTICATED
    }

    fun failForTest() {
        currentState = AuthState.FAILED
    }

    suspend fun logout() {
        tokenStore.clear()
        currentState = AuthState.SIGNED_OUT
    }
}
