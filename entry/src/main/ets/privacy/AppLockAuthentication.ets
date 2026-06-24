import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { userAuth } from '@kit.UserAuthenticationKit';

const USER_AUTH_SUCCESS_CODE: number = 12500000;

export interface AppLockAuthenticationResult {
  authenticated: boolean;
  unavailableMessage: string;
}

function isAuthTypeAvailable(type: userAuth.UserAuthType): boolean {
  try {
    userAuth.getAvailableStatus(type, userAuth.AuthTrustLevel.ATL3);
    return true;
  } catch (error) {
    return false;
  }
}

function appLockAuthTypes(): userAuth.UserAuthType[] {
  const authTypes: userAuth.UserAuthType[] = [];
  if (isAuthTypeAvailable(userAuth.UserAuthType.FACE)) {
    authTypes.push(userAuth.UserAuthType.FACE);
  }
  if (isAuthTypeAvailable(userAuth.UserAuthType.FINGERPRINT)) {
    authTypes.push(userAuth.UserAuthType.FINGERPRINT);
  }
  if (isAuthTypeAvailable(userAuth.UserAuthType.PIN)) {
    authTypes.push(userAuth.UserAuthType.PIN);
  }
  return authTypes;
}

function createAppLockChallenge(): Uint8Array {
  try {
    return cryptoFramework.createRandom().generateRandomSync(16).data;
  } catch (error) {
    const challenge = new Uint8Array(16);
    const now = Date.now();
    for (let index = 0; index < challenge.length; index++) {
      challenge[index] = Math.floor(Math.random() * 256) ^ ((now >> ((index % 4) * 8)) & 0xff);
    }
    return challenge;
  }
}

export async function authenticateAppLock(
  title: string,
  onAuthActiveChange: (active: boolean) => void
): Promise<AppLockAuthenticationResult> {
  const authTypes = appLockAuthTypes();
  if (authTypes.length === 0) {
    return {
      authenticated: false,
      unavailableMessage: '当前设备没有可用的面容、指纹或锁屏密码。'
    };
  }

  onAuthActiveChange(true);
  return new Promise<AppLockAuthenticationResult>((resolve) => {
    let resolved = false;
    const finish = (authenticated: boolean): void => {
      onAuthActiveChange(false);
      resolve({ authenticated, unavailableMessage: '' });
    };
    try {
      const authParam: userAuth.AuthParam = {
        challenge: createAppLockChallenge(),
        authType: authTypes,
        authTrustLevel: userAuth.AuthTrustLevel.ATL3
      };
      const widgetParam: userAuth.WidgetParam = {
        title
      };
      const userAuthInstance = userAuth.getUserAuthInstance(authParam, widgetParam);
      userAuthInstance.on('result', {
        onResult: (result: userAuth.UserAuthResult): void => {
          if (resolved) {
            return;
          }
          resolved = true;
          try {
            userAuthInstance.off('result');
          } catch (error) {
          }
          finish(result.result === USER_AUTH_SUCCESS_CODE);
        }
      });
      userAuthInstance.start();
    } catch (error) {
      if (!resolved) {
        resolved = true;
        finish(false);
      }
    }
  });
}
