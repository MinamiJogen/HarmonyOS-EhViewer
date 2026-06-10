import { NativeGallerySummary } from '../../ehviewer/EhNative';
import {
  GalleryCategoryColorResolver,
  GalleryImageResolver,
  GalleryOpenHandler,
  GalleryRatingFormatter,
  GalleryTransitionIdResolver,
  GalleryWaterfallView
} from '../../components/GalleryWaterfallView';
import { GalleryPagerBar, PagerAction } from '../../components/GalleryPagerBar';
import { SystemLoadingBlock } from '../../components/SystemLoadingBlock';

@Component
export struct SearchResultsPage {
  @Prop items: NativeGallerySummary[] = [];
  @Prop loading: boolean = false;
  @Prop loadingMessage: string = '正在加载图库...';
  @Prop error: string = '';
  @Prop resultCount: string = '';
  @Prop listUrl: string = '';
  @Prop emptyText: string = '没有搜索结果。换一个关键词再试。';
  @Prop firstEnabled: boolean = false;
  @Prop prevEnabled: boolean = false;
  @Prop nextEnabled: boolean = false;
  @Prop lastEnabled: boolean = false;
  @Prop imageVersion: number = 0;
  imageUrlForItem: GalleryImageResolver = (item: NativeGallerySummary): string => item.thumb;
  categoryColorForItem: GalleryCategoryColorResolver = (_category: string): string => '#607D8B';
  formatRatingValue: GalleryRatingFormatter = (rating: number): string => {
    return rating > 0 ? rating.toFixed(1) : '暂无';
  };
  transitionIdForItem: GalleryTransitionIdResolver = (_item: NativeGallerySummary): string => '';
  onOpenItem: GalleryOpenHandler = (_item: NativeGallerySummary): void => {};
  onFirst: PagerAction = (): void => {};
  onPrev: PagerAction = (): void => {};
  onNext: PagerAction = (): void => {};
  onLast: PagerAction = (): void => {};

  @Builder
  private LoadingBlock(): void {
    SystemLoadingBlock({
      message: this.loadingMessage,
      minHeight: 112
    });
  }

  @Builder
  private ErrorBlock(): void {
    if (this.error.length > 0) {
      Text(this.error)
        .width('100%')
        .fontSize(12)
        .fontColor('#B42318')
        .padding(12)
        .backgroundColor('#FFF3F2')
        .borderRadius(8);
    }
  }

  @Builder
  private ResultHeader(): void {
    Column() {
      Text(this.resultCount.length > 0 ? `${this.resultCount} 个结果` : `${this.items.length} 个画廊`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  build() {
    Column({ space: 12 }) {
      this.ErrorBlock();
      if (this.loading && this.items.length === 0) {
        this.LoadingBlock();
      } else {
        this.ResultHeader();
        GalleryWaterfallView({
          items: this.items,
          emptyText: this.emptyText,
          itemKeyPrefix: 'search',
          imageVersion: this.imageVersion,
          imageUrlForItem: this.imageUrlForItem,
          categoryColorForItem: this.categoryColorForItem,
          formatRatingValue: this.formatRatingValue,
          transitionIdForItem: this.transitionIdForItem,
          onOpenItem: this.onOpenItem
        });
        if (this.loading) {
          this.LoadingBlock();
        }
        GalleryPagerBar({
          firstEnabled: this.firstEnabled,
          prevEnabled: this.prevEnabled,
          nextEnabled: this.nextEnabled,
          lastEnabled: this.lastEnabled,
          onFirst: this.onFirst,
          onPrev: this.onPrev,
          onNext: this.onNext,
          onLast: this.onLast
        });
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }
}
