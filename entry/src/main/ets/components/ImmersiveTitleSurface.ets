@Component
export struct ImmersiveTitleSurface {
  @Prop surfaceHeight: number = 48;
  @BuilderParam content: () => void = this.EmptyContent;

  @Builder
  private EmptyContent(): void {
  }

  @Builder
  private TitleContent(): void {
    Column() {
      this.content();
    }
    .width('100%')
    .height(this.surfaceHeight)
    .justifyContent(FlexAlign.Center);
  }

  build() {
    // Generic materials require a native Navigation title ancestor. The parent
    // owns the page layout and safe areas; this surface contains only its title.
    Navigation() {
    }
    .width('100%')
    .height(this.surfaceHeight)
    .mode(NavigationMode.Stack)
    .title({ builder: this.TitleContent, height: this.surfaceHeight }, {
      backgroundColor: Color.Transparent,
      backgroundBlurStyle: BlurStyle.NONE,
      barStyle: BarStyle.STACK
    })
    .titleMode(NavigationTitleMode.Mini)
    .hideBackButton(true)
    .hideToolBar(true)
    .backgroundColor(Color.Transparent)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM]);
  }
}
