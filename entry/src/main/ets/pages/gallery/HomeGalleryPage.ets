import { NativeGallerySummary } from '../../ehviewer/EhNative';
import {
  GalleryCategoryColorResolver,
  GalleryImageResolver,
  GalleryOpenHandler,
  GalleryRankLabelResolver,
  GalleryRatingFormatter,
  GalleryTransitionIdResolver,
  GalleryWaterfallView
} from '../../components/GalleryWaterfallView';
import { GalleryPagerBar, PagerAction } from '../../components/GalleryPagerBar';
import { SystemLoadingBlock } from '../../components/SystemLoadingBlock';

@Component
export struct HomeGalleryPage {
  @Prop items: NativeGallerySummary[] = [];
  @Prop loading: boolean = false;
  @Prop loadingMessage: string = '正在加载图库...';
  @Prop error: string = '';
  @Prop emptyText: string = '暂无首页数据。点击刷新或切换站点后会加载站点首页画廊。';
  @Prop itemKeyPrefix: string = 'home';
  @Prop firstEnabled: boolean = false;
  @Prop prevEnabled: boolean = false;
  @Prop nextEnabled: boolean = false;
  @Prop lastEnabled: boolean = false;
  @Prop imageVersion: number = 0;
  @Prop loadingMinHeight: number = 112;
  @Prop contentWidth: number = 0;
  imageUrlForItem: GalleryImageResolver = (item: NativeGallerySummary): string => item.thumb;
  categoryColorForItem: GalleryCategoryColorResolver = (_category: string): string => '#607D8B';
  formatRatingValue: GalleryRatingFormatter = (rating: number): string => {
    return rating > 0 ? rating.toFixed(1) : '暂无';
  };
  transitionIdForItem: GalleryTransitionIdResolver = (_item: NativeGallerySummary): string => '';
  rankLabelForItem: GalleryRankLabelResolver = (_item: NativeGallerySummary, _index: number): string => '';
  onOpenItem: GalleryOpenHandler = (_item: NativeGallerySummary): void => {};
  onFirst: PagerAction = (): void => {};
  onPrev: PagerAction = (): void => {};
  onNext: PagerAction = (): void => {};
  onLast: PagerAction = (): void => {};

  @Builder
  private LoadingBlock(): void {
    SystemLoadingBlock({
      message: this.loadingMessage,
      minHeight: this.loadingMinHeight
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

  build() {
    Column({ space: 12 }) {
      this.ErrorBlock();
      if (this.loading && this.items.length === 0) {
        this.LoadingBlock();
      } else {
        GalleryWaterfallView({
          items: this.items,
          emptyText: this.emptyText,
          itemKeyPrefix: this.itemKeyPrefix,
          imageVersion: this.imageVersion,
          contentWidth: this.contentWidth,
          imageUrlForItem: this.imageUrlForItem,
          categoryColorForItem: this.categoryColorForItem,
          formatRatingValue: this.formatRatingValue,
          transitionIdForItem: this.transitionIdForItem,
          rankLabelForItem: this.rankLabelForItem,
          onOpenItem: this.onOpenItem
        });
        if (this.loading && this.loadingMessage.indexOf('下一页') >= 0) {
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
