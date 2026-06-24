import preferences from '@ohos.data.preferences';
import {
  APP_LOCK_AUTH_ACTIVE_STORAGE_KEY,
  APP_LOCK_ENABLED_KEY,
  APP_LOCK_FOREGROUND_REQUIRED_STORAGE_KEY,
  BACKGROUND_PREVIEW_PROTECTION_KEY
} from '../constants/AppConstants';

export interface PrivacySettingsSnapshot {
  appLockEnabled: boolean;
  backgroundPreviewProtectionEnabled: boolean;
}

export function initializePrivacyAppStorageDefaults(): void {
  AppStorage.setOrCreate<boolean>(APP_LOCK_AUTH_ACTIVE_STORAGE_KEY, false);
  AppStorage.setOrCreate<boolean>(APP_LOCK_ENABLED_KEY, false);
  AppStorage.setOrCreate<boolean>(BACKGROUND_PREVIEW_PROTECTION_KEY, true);
  AppStorage.setOrCreate<boolean>(APP_LOCK_FOREGROUND_REQUIRED_STORAGE_KEY, false);
}

export function readPreferenceBoolean(store: preferences.Preferences, key: string, fallback: boolean): boolean {
  try {
    return store.getSync(key, fallback) as boolean;
  } catch (error) {
    return fallback;
  }
}

export function readPrivacySettings(
  store: preferences.Preferences,
  currentAppLockEnabled: boolean = false,
  currentBackgroundPreviewProtectionEnabled: boolean = true
): PrivacySettingsSnapshot {
  return {
    appLockEnabled: readPreferenceBoolean(store, APP_LOCK_ENABLED_KEY, currentAppLockEnabled),
    backgroundPreviewProtectionEnabled: readPreferenceBoolean(
      store,
      BACKGROUND_PREVIEW_PROTECTION_KEY,
      currentBackgroundPreviewProtectionEnabled
    )
  };
}

export function syncPrivacySettingsToAppStorage(store: preferences.Preferences): PrivacySettingsSnapshot {
  const snapshot = readPrivacySettings(store, false, true);
  AppStorage.setOrCreate<boolean>(APP_LOCK_ENABLED_KEY, snapshot.appLockEnabled);
  AppStorage.setOrCreate<boolean>(
    BACKGROUND_PREVIEW_PROTECTION_KEY,
    snapshot.backgroundPreviewProtectionEnabled
  );
  return snapshot;
}

export function setAppLockForegroundRequired(required: boolean): void {
  try {
    AppStorage.setOrCreate<boolean>(APP_LOCK_FOREGROUND_REQUIRED_STORAGE_KEY, required);
  } catch (error) {
  }
}

export function setAppLockAuthActive(active: boolean): void {
  try {
    AppStorage.setOrCreate<boolean>(APP_LOCK_AUTH_ACTIVE_STORAGE_KEY, active);
  } catch (error) {
  }
}

export function isAppLockAuthActive(): boolean {
  try {
    const active = AppStorage.get<boolean>(APP_LOCK_AUTH_ACTIVE_STORAGE_KEY);
    return active === true;
  } catch (error) {
    return false;
  }
}

export function isBackgroundPreviewProtectionEnabled(store?: preferences.Preferences): boolean {
  try {
    const appStorageValue = AppStorage.get<boolean>(BACKGROUND_PREVIEW_PROTECTION_KEY);
    if (typeof appStorageValue === 'boolean') {
      return appStorageValue;
    }
  } catch (error) {
  }
  if (!store) {
    return true;
  }
  return readPreferenceBoolean(store, BACKGROUND_PREVIEW_PROTECTION_KEY, true);
}
