export type ReaderAreaChangeHandler = (oldValue: Area, newValue: Area) => void;
export type ReaderSwiperIndexChangeHandler = (index: number) => void;
export type ReaderVirtualPageHandler = (page: ReaderVirtualPage) => void;
export type ReaderPageTapHandler = (event: ClickEvent) => void;
export type ReaderPageResolveHandler = (page: ReaderVirtualPage) => Promise<ReaderResolvedPage>;
export type ReaderPageCacheHandler = (page: ReaderResolvedPage) => Promise<string>;
export type ReaderPageImageStateHandler = (page: ReaderVirtualPage, imageUrl: string) => void;

export interface ReaderVirtualPage {
  pageIndex: number;
  pageLabel: string;
  pageUrl: string;
  generation: number;
}

export interface ReaderResolvedPage {
  pageIndex: number;
  pageLabel: string;
  pageUrl: string;
  imageUrl: string;
  originImageUrl: string;
  skipHathKey?: string;
  sourceUrl: string;
  displayUrl: string;
}

export class ReaderPageDataSource implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private items: ReaderVirtualPage[] = [];
  private notifyPending: boolean = false;

  public reload(items: ReaderVirtualPage[]): void {
    if (this.isSameItems(items)) {
      return;
    }
    this.items = items;
    this.notifyDataReloaded();
  }

  public totalCount(): number {
    return this.items.length;
  }

  public getData(index: number): ReaderVirtualPage {
    if (index >= 0 && index < this.items.length) {
      return this.items[index];
    }
    return {
      pageIndex: Math.max(0, index),
      pageLabel: `${Math.max(0, index) + 1}`,
      pageUrl: '',
      generation: 0
    };
  }

  public registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener);
    }
  }

  public unregisterDataChangeListener(listener: DataChangeListener): void {
    this.listeners = this.listeners.filter((item: DataChangeListener) => item !== listener);
  }

  private isSameItems(items: ReaderVirtualPage[]): boolean {
    if (items.length !== this.items.length) {
      return false;
    }
    for (let index = 0; index < items.length; index++) {
      const left = items[index];
      const right = this.items[index];
      if (left.pageIndex !== right.pageIndex ||
        left.pageLabel !== right.pageLabel ||
        left.pageUrl !== right.pageUrl ||
        left.generation !== right.generation) {
        return false;
      }
    }
    return true;
  }

  private notifyDataReloaded(): void {
    if (this.notifyPending) {
      return;
    }
    this.notifyPending = true;
    setTimeout(() => {
      this.notifyPending = false;
      for (const listener of this.listeners) {
        listener.onDataReloaded();
      }
    }, 0);
  }
}

const EMPTY_READER_VIRTUAL_PAGE: ReaderVirtualPage = {
  pageIndex: 0,
  pageLabel: '1',
  pageUrl: '',
  generation: 0
};

const EMPTY_READER_RESOLVED_PAGE: ReaderResolvedPage = {
  pageIndex: 0,
  pageLabel: '1',
  pageUrl: '',
  imageUrl: '',
  originImageUrl: '',
  sourceUrl: '',
  displayUrl: ''
};
const READER_IMAGE_RENDER_RETRY_LIMIT: number = 2;
const READER_IMAGE_RENDER_RETRY_DELAY_MS: number = 360;

function readerErrorMessage(error: Object | string | undefined, fallback: string): string {
  const raw = `${error}`.replace('Error: ', '').trim();
  const lower = raw.toLowerCase();
  if (raw.length === 0 ||
    lower === 'undefined' ||
    lower === 'null' ||
    lower === 'object' ||
    lower === 'object object' ||
    lower === '[object object]') {
    return fallback;
  }
  return raw;
}

@Component
export struct ReaderSwiperView {
  controller: SwiperController = new SwiperController();
  dataSource: ReaderPageDataSource = new ReaderPageDataSource();
  currentIndex: number = 0;
  cachedCount: number = 2;
  vertical: boolean = false;
  itemSpace: number = 0;
  fitContain: boolean = true;

  onIndexChange: ReaderSwiperIndexChangeHandler = (_index: number): void => {};
  onPageAppear: ReaderVirtualPageHandler = (_page: ReaderVirtualPage): void => {};
  onPageTap: ReaderPageTapHandler = (_event: ClickEvent): void => {};
  onResolvePage: ReaderPageResolveHandler = async (_page: ReaderVirtualPage): Promise<ReaderResolvedPage> => {
    return EMPTY_READER_RESOLVED_PAGE;
  };
  onCachePageImage: ReaderPageCacheHandler = async (page: ReaderResolvedPage): Promise<string> => {
    return page.displayUrl;
  };
  onPageImageReady: ReaderPageImageStateHandler = (_page: ReaderVirtualPage, _imageUrl: string): void => {};
  onPageImageError: ReaderPageImageStateHandler = (_page: ReaderVirtualPage, _imageUrl: string): void => {};

  build() {
    Swiper(this.controller) {
      LazyForEach(this.dataSource, (item: ReaderVirtualPage) => {
        ReaderImagePage({
          page: item,
          fitContain: this.fitContain,
          onPageAppear: this.onPageAppear,
          onPageTap: this.onPageTap,
          onResolvePage: this.onResolvePage,
          onCachePageImage: this.onCachePageImage,
          onPageImageReady: this.onPageImageReady,
          onPageImageError: this.onPageImageError
        });
      }, (item: ReaderVirtualPage) => `${item.pageIndex}:${item.pageUrl}:${item.generation}`);
    }
    .width('100%')
    .height('100%')
    .index(this.currentIndex)
    .cachedCount(this.cachedCount)
    .vertical(this.vertical)
    .itemSpace(this.itemSpace)
    .indicator(false)
    .loop(false)
    .duration(180)
    .effectMode(EdgeEffect.Spring)
    .onChange((index: number) => {
      this.onIndexChange(index);
    });
  }
}

@Component
struct ReaderImagePage {
  page: ReaderVirtualPage = EMPTY_READER_VIRTUAL_PAGE;
  fitContain: boolean = true;
  onPageAppear: ReaderVirtualPageHandler = (_page: ReaderVirtualPage): void => {};
  onPageTap: ReaderPageTapHandler = (_event: ClickEvent): void => {};
  onResolvePage: ReaderPageResolveHandler = async (_page: ReaderVirtualPage): Promise<ReaderResolvedPage> => {
    return EMPTY_READER_RESOLVED_PAGE;
  };
  onCachePageImage: ReaderPageCacheHandler = async (page: ReaderResolvedPage): Promise<string> => {
    return page.displayUrl;
  };
  onPageImageReady: ReaderPageImageStateHandler = (_page: ReaderVirtualPage, _imageUrl: string): void => {};
  onPageImageError: ReaderPageImageStateHandler = (_page: ReaderVirtualPage, _imageUrl: string): void => {};

  @State private pageLabel: string = '';
  @State private imageUrl: string = '';
  @State private progress: number = 0;
  @State private loading: boolean = true;
  @State private imageReady: boolean = false;
  @State private error: string = '';

  private activeKey: string = '';
  private loadGeneration: number = 0;
  private progressTimerId: number = -1;
  private renderRetryCount: number = 0;
  private renderRetryTimerId: number = -1;
  private lastFailureReason: string = '';

  aboutToAppear(): void {
    this.startLoad(true);
  }

  aboutToDisappear(): void {
    this.loadGeneration++;
    this.stopProgressTicker();
    this.stopRenderRetryTimer();
  }

  private pageKey(): string {
    return `${this.page.pageIndex}:${this.page.pageUrl}:${this.page.generation}`;
  }

  private startLoad(resetRetryCount: boolean): void {
    const nextKey = this.pageKey();
    if (this.activeKey === nextKey && (this.loading || this.imageReady || this.error.length > 0)) {
      return;
    }
    if (resetRetryCount) {
      this.renderRetryCount = 0;
      this.lastFailureReason = '';
    }
    this.activeKey = nextKey;
    const generation = ++this.loadGeneration;
    this.pageLabel = this.page.pageLabel.length > 0 ? this.page.pageLabel : `${this.page.pageIndex + 1}`;
    this.imageUrl = '';
    this.progress = 0;
    this.loading = true;
    this.imageReady = false;
    this.error = '';
    this.onPageAppear(this.page);
    this.stopRenderRetryTimer();
    this.startProgressTicker();
    void this.loadPage(generation);
  }

  private async loadPage(generation: number): Promise<void> {
    try {
      this.setProgress(8);
      const resolved = await this.onResolvePage(this.page);
      if (generation !== this.loadGeneration) {
        return;
      }
      this.pageLabel = resolved.pageLabel.length > 0 ? resolved.pageLabel : `${resolved.pageIndex + 1}`;
      this.setProgress(34);
      let cachedUrl = '';
      try {
        cachedUrl = await this.onCachePageImage(resolved);
      } catch (cacheError) {
        this.lastFailureReason = readerErrorMessage(cacheError, '图片缓存失败');
        cachedUrl = '';
      }
      if (generation !== this.loadGeneration) {
        return;
      }
      const nextUrl = cachedUrl.length > 0 ? cachedUrl :
        (resolved.displayUrl.length > 0 ? resolved.displayUrl : resolved.sourceUrl);
      if (nextUrl.length === 0) {
        throw new Error(this.lastFailureReason.length > 0 ? this.lastFailureReason : '图片地址为空');
      }
      this.imageUrl = nextUrl;
      this.setProgress(88);
    } catch (error) {
      if (generation !== this.loadGeneration) {
        return;
      }
      const message = readerErrorMessage(error, '图片加载失败');
      this.lastFailureReason = message;
      this.error = this.readerFinalErrorMessage(message);
      this.loading = false;
      this.imageReady = false;
      this.stopProgressTicker();
    }
  }

  private readerFinalErrorMessage(fallback: string = '图片加载失败'): string {
    const reason = this.lastFailureReason.length > 0 ? this.lastFailureReason : fallback;
    if (reason.startsWith('图片加载失败') ||
      reason.startsWith('图片缓存失败') ||
      reason.startsWith('图片渲染失败') ||
      reason.startsWith('阅读器图片下载失败') ||
      reason.startsWith('当前图片缓存失败')) {
      return reason;
    }
    return `图片加载失败：${reason}`;
  }

  private setProgress(value: number): void {
    this.progress = Math.max(this.progress, Math.min(100, Math.floor(value)));
  }

  private startProgressTicker(): void {
    this.stopProgressTicker();
    const handle = setInterval(() => {
      if (!this.loading || this.imageReady) {
        return;
      }
      if (this.progress < 92) {
        const step = this.progress < 50 ? 4 : 2;
        this.progress = Math.min(92, this.progress + step);
      }
    }, 260);
    this.progressTimerId = Number(handle);
  }

  private stopProgressTicker(): void {
    if (this.progressTimerId >= 0) {
      clearInterval(this.progressTimerId);
      this.progressTimerId = -1;
    }
  }

  private stopRenderRetryTimer(): void {
    if (this.renderRetryTimerId >= 0) {
      clearTimeout(this.renderRetryTimerId);
      this.renderRetryTimerId = -1;
    }
  }

  private markImageReady(): void {
    this.progress = 100;
    this.loading = false;
    this.imageReady = true;
    this.error = '';
    this.renderRetryCount = 0;
    this.stopProgressTicker();
    this.stopRenderRetryTimer();
    this.onPageImageReady(this.page, this.imageUrl);
  }

  private markImageError(): void {
    this.onPageImageError(this.page, this.imageUrl);
    if (this.renderRetryCount < READER_IMAGE_RENDER_RETRY_LIMIT) {
      this.renderRetryCount++;
      this.imageUrl = '';
      this.progress = 0;
      this.loading = true;
      this.imageReady = false;
      this.error = '图片加载失败，正在重试...';
      this.startProgressTicker();
      const retryKey = this.pageKey();
      this.stopRenderRetryTimer();
      const handle = setTimeout(() => {
        this.renderRetryTimerId = -1;
        if (this.pageKey() !== retryKey) {
          return;
        }
        this.activeKey = '';
        this.startLoad(false);
      }, READER_IMAGE_RENDER_RETRY_DELAY_MS);
      this.renderRetryTimerId = Number(handle);
      return;
    }
    this.loading = false;
    this.imageReady = false;
    this.error = this.readerFinalErrorMessage('图片渲染失败，请重试');
    this.stopProgressTicker();
    this.stopRenderRetryTimer();
  }

  @Builder
  private LoadingState(): void {
    if (!this.imageReady) {
      Column({ space: 10 }) {
        if (this.error.length === 0) {
          LoadingProgress()
            .width(40)
            .height(40);
          Text(`${this.progress}%`)
            .fontSize(12)
            .fontColor('#6F5964');
        } else {
          Text(this.error)
            .fontSize(13)
            .fontColor('#B42318')
            .textAlign(TextAlign.Center)
            .maxLines(2);
          Button('重试')
            .height(28)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#B42318')
            .borderRadius(6)
            .onClick(() => {
              this.onPageImageError(this.page, this.imageUrl);
              this.activeKey = '';
              this.startLoad(true);
            });
        }
        if (this.pageLabel.length > 0) {
          Text(`第 ${this.pageLabel} 页`)
            .fontSize(11)
            .fontColor('#9A7D8A');
        }
      }
      .width(176)
      .padding({ left: 14, right: 14, top: 16, bottom: 16 })
      .backgroundColor('#FFFFFFFF')
      .borderRadius(6)
      .alignItems(HorizontalAlign.Center);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF');

      if (this.imageUrl.length > 0) {
        Image(this.imageUrl)
          .width('100%')
          .height('100%')
          .objectFit(this.fitContain ? ImageFit.Contain : ImageFit.Cover)
          .backgroundColor('#FFFFFF')
          .opacity(this.imageReady ? 1 : 0)
          .onComplete(() => {
            this.markImageReady();
          })
          .onError(() => {
            this.markImageError();
          });
      }

      this.LoadingState();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .onClick((event: ClickEvent) => {
      this.onPageTap(event);
    });
  }
}

@Component
export struct ReaderFullscreenPage {
  customLightness: boolean = false;
  overlayMaskColor: string = '#00000000';
  onReaderAreaChange: ReaderAreaChangeHandler = (_oldValue: Area, _newValue: Area): void => {};

  @BuilderParam negativeLayerContent: () => void = this.EmptySlot;
  @BuilderParam currentLayerContent: () => void = this.EmptySlot;
  @BuilderParam positiveLayerContent: () => void = this.EmptySlot;
  @BuilderParam loadingOverlayContent: () => void = this.EmptySlot;
  @BuilderParam controlsContent: () => void = this.EmptySlot;

  @Builder
  private EmptySlot(): void {
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      this.negativeLayerContent();
      this.currentLayerContent();
      this.positiveLayerContent();

      if (this.customLightness) {
        Column() {
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.overlayMaskColor);
      }

      this.loadingOverlayContent();
      this.controlsContent();
    }
    .width('100%')
    .height('100%')
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.onReaderAreaChange(oldValue, newValue);
    })
    .backgroundColor('#000000')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}

@Component
export struct ReaderInlinePage {
  @BuilderParam content: () => void = this.EmptySlot;

  @Builder
  private EmptySlot(): void {
  }

  build() {
    Column({ space: 12 }) {
      this.content();
    }
    .width('100%');
  }
}
