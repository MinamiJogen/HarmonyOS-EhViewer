import { ReaderToggleChangeHandler } from '../../models/AppModels';
import { IMMERSIVE_CONTROL_MATERIAL } from '../../styles/ImmersiveMaterials';

@Component
export struct PrivacySettingsCard {
  @Prop appLockEnabled: boolean = false;
  @Prop appLockAuthInProgress: boolean = false;
  @Prop appLockStatus: string = '';
  @Prop backgroundPreviewProtectionEnabled: boolean = true;
  onAppLockChange: ReaderToggleChangeHandler = (_isOn: boolean): void => {};
  onBackgroundPreviewProtectionChange: ReaderToggleChangeHandler = (_isOn: boolean): void => {};

  @Builder
  private Header(): void {
    Text('隐私保护')
      .width('100%')
      .fontSize(18)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('sys.color.font_primary'))
      .padding({ left: 16, right: 16, top: 16, bottom: 12 });
  }

  @Builder
  private SwitchRow(
    title: string,
    description: string,
    value: boolean,
    enabled: boolean,
    onChange: ReaderToggleChangeHandler
  ): void {
    ListItem({ style: ListItemStyle.CARD }) {
      Row({ space: 16 }) {
        Column({ space: 4 }) {
          Text(title)
            .fontSize(16)
            .fontColor($r('sys.color.font_primary'));
          Text(description)
            .fontSize(13)
            .lineHeight(18)
            .fontColor($r('sys.color.font_secondary'));
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
        Toggle({ type: ToggleType.Switch, isOn: value })
          .systemMaterial(IMMERSIVE_CONTROL_MATERIAL)
          .responseRegion({ x: 0, y: -8, width: '100%', height: 48 })
          .enabled(enabled)
          .accessibilityText(title)
          .accessibilityDescription(value ? '已开启' : '已关闭')
          .onChange((isOn: boolean) => {
            onChange(isOn);
          });
      }
      .width('100%')
      .constraintSize({ minHeight: 72 })
      .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center);
    }
    .height(undefined);
  }

  build() {
    ListItemGroup({ style: ListItemGroupStyle.CARD, header: this.Header }) {
      this.SwitchRow(
        '锁定 App',
        '返回应用时使用面容、指纹或锁屏密码验证',
        this.appLockEnabled,
        !this.appLockAuthInProgress,
        this.onAppLockChange
      );
      this.SwitchRow(
        '后台预览保护',
        '在最近任务中隐藏应用画面',
        this.backgroundPreviewProtectionEnabled,
        true,
        this.onBackgroundPreviewProtectionChange
      );
      if ((this.appLockEnabled || this.appLockAuthInProgress) && this.appLockStatus.length > 0) {
        ListItem({ style: ListItemStyle.CARD }) {
          Text(this.appLockStatus)
            .fontSize(13)
            .lineHeight(20)
            .fontColor($r('sys.color.font_secondary'))
            .width('100%')
            .padding({ left: 12, right: 12, top: 12, bottom: 12 });
        }
        .height(undefined);
      }
    }
    .width('100%')
    .divider({ strokeWidth: 0.5, color: $r('sys.color.comp_divider'), startMargin: 20, endMargin: 20 });
  }
}
