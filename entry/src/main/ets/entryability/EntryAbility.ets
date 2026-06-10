import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CustomColors, CustomTheme, ThemeControl, window } from '@kit.ArkUI';
import webview from '@ohos.web.webview';
import connection from '@ohos.net.connection';
import { NativeEhClient } from '../ehviewer/EhNative';

const DOMAIN = 0x0000;

const EH_CLOUDFLARE_HOSTS: string[] = [
  'e-hentai.org',
  'repo.e-hentai.org',
  'forums.e-hentai.org'
];

class EhViewerThemeColors implements CustomColors {
  brand: ResourceColor = '#C86B8C';
  warning: ResourceColor = '#B42318';
  alert: ResourceColor = '#B54708';
  confirm: ResourceColor = '#8A6F3E';
  fontEmphasize: ResourceColor = '#A85474';
  iconEmphasize: ResourceColor = '#A85474';
  iconSubEmphasize: ResourceColor = '#66A85474';
  backgroundEmphasize: ResourceColor = '#C86B8C';
  compBackgroundEmphasize: ResourceColor = '#C86B8C';
  compEmphasizeSecondary: ResourceColor = '#33C86B8C';
  compEmphasizeTertiary: ResourceColor = '#19C86B8C';
  interactiveFocus: ResourceColor = '#C86B8C';
  interactiveActive: ResourceColor = '#C86B8C';
}

class EhViewerTheme implements CustomTheme {
  colors: CustomColors = new EhViewerThemeColors();
}

const EH_BUILT_IN_HOSTS: Record<string, string[]> = {
  'e-hentai.org': [
    '104.20.18.168',
    '104.20.19.168',
    '172.66.132.196',
    '172.66.140.62',
    '172.67.2.238'
  ],
  'repo.e-hentai.org': [
    '104.20.18.168',
    '104.20.19.168',
    '172.67.2.238'
  ],
  'forums.e-hentai.org': [
    '172.66.132.196',
    '172.66.140.62'
  ],
  'upld.e-hentai.org': [
    '89.149.221.236',
    '95.211.208.236'
  ],
  'ehgt.org': [
    '109.236.85.28',
    '62.112.8.21',
    '89.39.106.43'
  ],
  'exhentai.org': [
    '178.175.128.251',
    '178.175.128.252',
    '178.175.128.253',
    '178.175.128.254',
    '178.175.129.251',
    '178.175.129.252',
    '178.175.129.253',
    '178.175.129.254',
    '178.175.132.19',
    '178.175.132.20',
    '178.175.132.21',
    '178.175.132.22'
  ],
  'upld.exhentai.org': [
    '178.175.132.22',
    '178.175.129.254',
    '178.175.128.254'
  ],
  's.exhentai.org': [
    '178.175.129.253',
    '178.175.129.254',
    '178.175.128.253',
    '178.175.128.254',
    '178.175.132.21',
    '178.175.132.22'
  ],
  'raw.githubusercontent.com': [
    '151.101.0.133',
    '151.101.64.133',
    '151.101.128.133',
    '151.101.192.133'
  ]
};

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    try {
      webview.WebviewController.initializeWebEngine();
      webview.WebCookieManager.putAcceptCookieEnabled(true);
      webview.WebCookieManager.putAcceptThirdPartyCookieEnabled(true);
      webview.WebviewController.setAppCustomUserAgent(NativeEhClient.USER_AGENT);
      this.clearCloudflareHostOverrides();
      this.configureEhHosts();
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize web engine. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  private configureEhHosts(): void {
    for (const host of Object.keys(EH_BUILT_IN_HOSTS)) {
      if (this.isCloudflareHost(host)) {
        continue;
      }
      const addresses = EH_BUILT_IN_HOSTS[host];
      if (!addresses || addresses.length === 0) {
        continue;
      }
      const shuffledAddresses = this.shuffleAddresses(addresses);
      try {
        void connection.addCustomDnsRule(host, shuffledAddresses).catch((error: Error) => {
          hilog.warn(DOMAIN, 'testTag', 'Failed to add DNS rule for %{public}s. Cause: %{public}s',
            host, `${error}`);
        });
      } catch (error) {
        hilog.warn(DOMAIN, 'testTag', 'Failed to add DNS rule for %{public}s. Cause: %{public}s',
          host, `${error}`);
      }
      try {
        webview.WebviewController.setHostIP(host, shuffledAddresses[0], 60 * 60 * 24);
      } catch (error) {
      }
    }
  }

  private isCloudflareHost(host: string): boolean {
    return EH_CLOUDFLARE_HOSTS.indexOf(host) >= 0;
  }

  private clearCloudflareHostOverrides(): void {
    for (const host of EH_CLOUDFLARE_HOSTS) {
      try {
        webview.WebviewController.clearHostIP(host);
      } catch (error) {
      }
      try {
        void connection.removeCustomDnsRule(host).catch((error: Error) => {
          hilog.warn(DOMAIN, 'testTag', 'Failed to remove DNS rule for %{public}s. Cause: %{public}s',
            host, `${error}`);
        });
      } catch (error) {
        hilog.warn(DOMAIN, 'testTag', 'Failed to remove DNS rule for %{public}s. Cause: %{public}s',
          host, `${error}`);
      }
    }
  }

  private shuffleAddresses(addresses: string[]): string[] {
    const result = addresses.slice();
    for (let index = result.length - 1; index > 0; index--) {
      const swapIndex = Math.floor(Math.random() * (index + 1));
      const value = result[index];
      result[index] = result[swapIndex];
      result[swapIndex] = value;
    }
    return result;
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  private async configureImmersiveMainWindow(windowStage: window.WindowStage): Promise<void> {
    const mainWindow = await windowStage.getMainWindow();
    await mainWindow.setWindowLayoutFullScreen(true);
    await mainWindow.setWindowSystemBarEnable(['status', 'navigation']);
    await mainWindow.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      navigationBarColor: '#00000000',
      isStatusBarLightIcon: false,
      isNavigationBarLightIcon: false,
      statusBarContentColor: '#2B2027',
      navigationBarContentColor: '#2B2027'
    });
  }

  private loadMainContent(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      try {
        ThemeControl.setDefaultTheme(new EhViewerTheme());
      } catch (themeError) {
        hilog.warn(DOMAIN, 'testTag', 'Failed to apply theme. Cause: %{public}s', JSON.stringify(themeError));
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    void this.configureImmersiveMainWindow(windowStage)
      .then(() => {
        this.loadMainContent(windowStage);
      })
      .catch((error: Error) => {
        hilog.warn(DOMAIN, 'testTag', 'Failed to configure immersive window. Cause: %{public}s', `${error}`);
        this.loadMainContent(windowStage);
      });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
