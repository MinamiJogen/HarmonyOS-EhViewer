export type PagerAction = () => void;

@Component
export struct GalleryPagerBar {
  @Prop firstEnabled: boolean = false;
  @Prop prevEnabled: boolean = false;
  @Prop nextEnabled: boolean = false;
  @Prop lastEnabled: boolean = false;
  onFirst: PagerAction = (): void => {};
  onPrev: PagerAction = (): void => {};
  onNext: PagerAction = (): void => {};
  onLast: PagerAction = (): void => {};

  private anyEnabled(): boolean {
    return this.firstEnabled || this.prevEnabled || this.nextEnabled || this.lastEnabled;
  }

  @Builder
  private PagerButton(title: string, enabled: boolean, action: PagerAction): void {
    Button(title)
      .layoutWeight(1)
      .height(28)
      .fontSize(12)
      .fontColor(enabled ? '#2B2027' : '#9A7D8A')
      .backgroundColor(enabled ? '#F8E4ED' : '#EEEEEE')
      .borderRadius(8)
      .enabled(enabled)
      .onClick(() => {
        action();
      });
  }

  build() {
    if (this.anyEnabled()) {
      Row({ space: 8 }) {
        this.PagerButton('首页', this.firstEnabled, this.onFirst);
        this.PagerButton('上页', this.prevEnabled, this.onPrev);
        this.PagerButton('下页', this.nextEnabled, this.onNext);
        this.PagerButton('末页', this.lastEnabled, this.onLast);
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#FFFFFF')
      .borderRadius(8);
    }
  }
}
