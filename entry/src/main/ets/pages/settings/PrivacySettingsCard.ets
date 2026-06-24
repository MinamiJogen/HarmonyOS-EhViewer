import { ReaderToggleChangeHandler } from '../../models/AppModels';

@Component
export struct PrivacySettingsCard {
  @Prop appLockEnabled: boolean = false;
  @Prop appLockAuthInProgress: boolean = false;
  @Prop appLockStatus: string = '';
  @Prop backgroundPreviewProtectionEnabled: boolean = true;
  onAppLockChange: ReaderToggleChangeHandler = (_isOn: boolean): void => {};
  onBackgroundPreviewProtectionChange: ReaderToggleChangeHandler = (_isOn: boolean): void => {};

  @Builder
  private SwitchRow(
    title: string,
    value: boolean,
    enabled: boolean,
    onChange: ReaderToggleChangeHandler
  ): void {
    Row({ space: 12 }) {
      Text(title)
        .layoutWeight(1)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(enabled ? '#2B2027' : '#9A7D8A')
        .maxLines(1);

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#C86B8C')
        .switchPointColor('#FFFFFF')
        .enabled(enabled)
        .accessibilityText(value ? `${title}已开启` : `${title}已关闭`)
        .onChange((isOn: boolean) => {
          onChange(isOn);
        });
    }
    .width('100%')
    .height(40)
    .alignItems(VerticalAlign.Center);
  }

  build() {
    Column({ space: 8 }) {
      Text('隐私保护')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');

      this.SwitchRow(
        '锁定 App',
        this.appLockEnabled,
        !this.appLockAuthInProgress,
        this.onAppLockChange
      );

      Divider()
        .strokeWidth(1)
        .color('#F0D8E2');

      this.SwitchRow(
        '后台预览保护',
        this.backgroundPreviewProtectionEnabled,
        true,
        this.onBackgroundPreviewProtectionChange
      );

      if (this.appLockEnabled || this.appLockAuthInProgress) {
        Text(this.appLockStatus)
          .fontSize(12)
          .lineHeight(18)
          .fontColor('#7C6470')
          .width('100%');
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }
}
