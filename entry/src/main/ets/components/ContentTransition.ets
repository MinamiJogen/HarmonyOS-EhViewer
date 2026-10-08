import { FrameCallback } from '@kit.ArkUI';

class ContentTransitionFrameCallback extends FrameCallback {
  private action: () => void;

  constructor(action: () => void) {
    super();
    this.action = action;
  }

  onFrame(_frameTime: number): void {
    this.action();
  }
}

@Component
export struct ContentTransition {
  @Prop @Watch('restartTransition') changeKey: string = '';
  @Prop fillHeight: boolean = false;
  @Prop animateOnAppear: boolean = true;
  @BuilderParam content: () => void = this.EmptyContent;
  @State private contentOpacity: number = 1;
  @State private contentOffsetY: number = 0;
  private active: boolean = false;
  private generation: number = 0;

  aboutToAppear(): void {
    this.active = true;
    if (this.animateOnAppear) {
      this.restartTransition();
    } else {
      this.contentOpacity = 1;
      this.contentOffsetY = 0;
    }
  }

  aboutToDisappear(): void {
    this.active = false;
    this.generation++;
  }

  private restartTransition(): void {
    if (!this.active) {
      return;
    }
    const generation = ++this.generation;
    this.contentOpacity = 0;
    this.contentOffsetY = 8;
    this.getUIContext().postFrameCallback(new ContentTransitionFrameCallback((): void => {
      if (!this.active || generation !== this.generation) {
        return;
      }
      this.getUIContext().animateTo({ duration: 200, curve: Curve.EaseOut }, (): void => {
        this.contentOpacity = 1;
        this.contentOffsetY = 0;
      });
    }));
  }

  @Builder
  private EmptyContent(): void {
  }

  build() {
    // Keep child identity and scroll controllers. Only a semantic view change
    // restarts this animation; list appends and progress updates do not.
    Column() {
      this.content();
    }
    .width('100%')
    .height(this.fillHeight ? '100%' : undefined)
    .alignItems(HorizontalAlign.Start)
    .opacity(this.contentOpacity)
    .translate({ y: this.contentOffsetY });
  }
}
