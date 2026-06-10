@Component
export struct SystemLoadingBlock {
  @Prop message: string = '';
  @Prop minHeight: number = 96;

  build() {
    Column({ space: 10 }) {
      LoadingProgress()
        .width(32)
        .height(32);
      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#6F5964')
          .textAlign(TextAlign.Center)
          .maxLines(2);
      }
    }
    .width('100%')
    .constraintSize({ minHeight: this.minHeight })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center);
  }
}
