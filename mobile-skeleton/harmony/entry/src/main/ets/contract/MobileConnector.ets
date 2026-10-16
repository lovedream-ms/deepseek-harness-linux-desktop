export enum AuthState {
  SIGNED_OUT = 'signed_out',
  AWAITING_BROWSER = 'awaiting_browser',
  CALLBACK_RECEIVED = 'callback_received',
  AUTHENTICATED = 'authenticated',
  FAILED = 'failed',
}

export type LoginPlan = {
  networkEnabled: boolean
  endpointConfigured: boolean
  requiresFormalContract: boolean
}

export type TokenSnapshot = {
  hasAccessToken: boolean
  hasRefreshToken: boolean
  expiresAtEpochSeconds?: number
}

export interface SecureTokenStore {
  read(): Promise<TokenSnapshot | undefined>
  write(snapshot: TokenSnapshot): Promise<void>
  clear(): Promise<void>
}

export interface BrowserAuthSession {
  open(plan: LoginPlan): Promise<void>
}

export interface ConnectorTransport {
  execute(operation: string, request: Record<string, Object>): Promise<Record<string, Object>>
}

export class OfflineMobileConnector {
  private currentState: AuthState = AuthState.SIGNED_OUT

  state(): AuthState {
    return this.currentState
  }

  beginLogin(): LoginPlan {
    if (
      this.currentState !== AuthState.SIGNED_OUT &&
      this.currentState !== AuthState.FAILED
    ) {
      throw new Error('login is already in progress')
    }
    this.currentState = AuthState.AWAITING_BROWSER
    return {
      networkEnabled: false,
      endpointConfigured: false,
      requiresFormalContract: true,
    }
  }

  receiveCallbackForTest(): void {
    if (this.currentState !== AuthState.AWAITING_BROWSER) {
      throw new Error('callback is not expected in the current state')
    }
    this.currentState = AuthState.CALLBACK_RECEIVED
  }

  markAuthenticatedForTest(): void {
    if (this.currentState !== AuthState.CALLBACK_RECEIVED) {
      throw new Error('authentication result is not expected in the current state')
    }
    this.currentState = AuthState.AUTHENTICATED
  }

  failForTest(): void {
    this.currentState = AuthState.FAILED
  }
}
