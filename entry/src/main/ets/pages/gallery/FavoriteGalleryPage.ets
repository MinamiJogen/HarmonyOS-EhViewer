import { NativeGallerySummary } from '../../ehviewer/EhNative';
import { GalleryPagerBar, PagerAction } from '../../components/GalleryPagerBar';
import { SystemLoadingBlock } from '../../components/SystemLoadingBlock';

export type FavoriteGalleryImageResolver = (item: NativeGallerySummary) => string;
export type FavoriteGalleryCategoryColorResolver = (category: string) => string;
export type FavoriteGalleryRatingFormatter = (rating: number) => string;
export type FavoriteGalleryOpenHandler = (item: NativeGallerySummary) => void;
export type FavoriteGalleryTransitionIdResolver = (item: NativeGallerySummary) => string;

const FAVORITE_WATERFALL_MIN_COLUMNS: number = 2;
const FAVORITE_WATERFALL_COLUMN_GAP: number = 10;
const FAVORITE_WATERFALL_ROW_GAP: number = 12;
const FAVORITE_WATERFALL_PREFERRED_ITEM_WIDTH: number = 176;

@Component
struct FavoriteGalleryWaterfallView {
  @Prop items: NativeGallerySummary[] = [];
  @Prop emptyText: string = '';
  @Prop itemKeyPrefix: string = 'favorite';
  @Prop imageVersion: number = 0;
  @State private containerWidth: number = 0;
  imageUrlForItem: FavoriteGalleryImageResolver = (item: NativeGallerySummary): string => item.thumb;
  categoryColorForItem: FavoriteGalleryCategoryColorResolver = (_category: string): string => '#607D8B';
  formatRatingValue: FavoriteGalleryRatingFormatter = (rating: number): string => {
    return rating > 0 ? rating.toFixed(1) : '暂无';
  };
  transitionIdForItem: FavoriteGalleryTransitionIdResolver = (_item: NativeGallerySummary): string => '';
  onOpenItem: FavoriteGalleryOpenHandler = (_item: NativeGallerySummary): void => {};

  private coverHeight(item: NativeGallerySummary): number {
    if (item.pages > 120) {
      return 208;
    }
    if (item.pages > 80) {
      return 188;
    }
    return 154;
  }

  private cardHeight(item: NativeGallerySummary): number {
    return this.coverHeight(item) + 150;
  }

  private lengthToNumber(value: Length): number {
    if (typeof value === 'number') {
      return value;
    }
    if (typeof value === 'string') {
      const parsed = Number.parseFloat(value);
      return Number.isFinite(parsed) ? parsed : 0;
    }
    return 0;
  }

  private updateContainerWidth(value: Length): void {
    const nextWidth = this.lengthToNumber(value);
    if (nextWidth <= 0) {
      return;
    }
    if (Math.abs(nextWidth - this.containerWidth) >= 1) {
      this.containerWidth = nextWidth;
    }
  }

  private itemWidthForColumns(width: number, columns: number): number {
    if (columns <= 0) {
      return width;
    }
    return (width - FAVORITE_WATERFALL_COLUMN_GAP * (columns - 1)) / columns;
  }

  private columnCount(): number {
    if (this.containerWidth <= 0) {
      return FAVORITE_WATERFALL_MIN_COLUMNS;
    }
    let bestColumns = FAVORITE_WATERFALL_MIN_COLUMNS;
    let bestDistance = Math.abs(this.itemWidthForColumns(this.containerWidth, bestColumns) -
      FAVORITE_WATERFALL_PREFERRED_ITEM_WIDTH);
    const widestUsefulColumns = Math.max(
      FAVORITE_WATERFALL_MIN_COLUMNS,
      Math.ceil((this.containerWidth + FAVORITE_WATERFALL_COLUMN_GAP) /
        (FAVORITE_WATERFALL_PREFERRED_ITEM_WIDTH + FAVORITE_WATERFALL_COLUMN_GAP)) + 1
    );
    for (let columns = FAVORITE_WATERFALL_MIN_COLUMNS + 1; columns <= widestUsefulColumns; columns++) {
      const distance = Math.abs(this.itemWidthForColumns(this.containerWidth, columns) -
        FAVORITE_WATERFALL_PREFERRED_ITEM_WIDTH);
      if (distance < bestDistance) {
        bestColumns = columns;
        bestDistance = distance;
      }
    }
    return bestColumns;
  }

  private columnsTemplate(): string {
    const columns = this.columnCount();
    let template = '';
    for (let index = 0; index < columns; index++) {
      template = template.length > 0 ? `${template} 1fr` : '1fr';
    }
    return template;
  }

  private contentHeight(): number {
    const columns = this.columnCount();
    const columnHeights: number[] = [];
    for (let index = 0; index < columns; index++) {
      columnHeights.push(0);
    }
    for (let itemIndex = 0; itemIndex < this.items.length; itemIndex++) {
      let targetColumn = 0;
      for (let columnIndex = 1; columnIndex < columns; columnIndex++) {
        if (columnHeights[columnIndex] < columnHeights[targetColumn]) {
          targetColumn = columnIndex;
        }
      }
      if (columnHeights[targetColumn] > 0) {
        columnHeights[targetColumn] += FAVORITE_WATERFALL_ROW_GAP;
      }
      columnHeights[targetColumn] += this.cardHeight(this.items[itemIndex]);
    }
    let total = 0;
    for (let index = 0; index < columnHeights.length; index++) {
      total = Math.max(total, columnHeights[index]);
    }
    return Math.max(180, total);
  }

  private itemKey(item: NativeGallerySummary): string {
    return `${this.itemKeyPrefix}:${item.gid}:${item.token}`;
  }

  private resolvedImageUrl(item: NativeGallerySummary): string {
    this.imageVersion;
    return this.imageUrlForItem(item);
  }

  @Builder
  private GalleryCover(item: NativeGallerySummary): void {
    if (item.thumb.length > 0) {
      Image(this.resolvedImageUrl(item))
        .width('100%')
        .height(this.coverHeight(item))
        .borderRadius(8)
        .clip(true)
        .objectFit(ImageFit.Cover)
        .geometryTransition(this.transitionIdForItem(item))
        .transition(TransitionEffect.OPACITY);
    } else {
      Column() {
        Text('无封面')
          .fontSize(12)
          .fontColor('#9A7D8A');
      }
      .width('100%')
      .height(154)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F3E3EA')
      .borderRadius(8);
    }
  }

  @Builder
  private GalleryCard(item: NativeGallerySummary): void {
    Column({ space: 8 }) {
      this.GalleryCover(item);

      Text(item.title.length > 0 ? item.title : `${item.gid}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2B2027')
        .maxLines(2);
      if (item.titleJpn.length > 0 && item.titleJpn !== item.title) {
        Text(item.titleJpn)
          .fontSize(11)
          .fontColor('#7C6470')
          .maxLines(1);
      }

      Row({ space: 6 }) {
        Text(item.categoryLabel.toUpperCase())
          .fontSize(10)
          .fontColor('#FFFFFF')
          .padding({ left: 7, right: 7, top: 3, bottom: 3 })
          .backgroundColor(this.categoryColorForItem(item.categoryLabel))
          .borderRadius(9);
        Text(`${item.pages}P`)
          .fontSize(11)
          .fontColor('#7C6470');
      }

      Text(item.uploader.length > 0 ? item.uploader : '未知上传者')
        .fontSize(11)
        .fontColor('#7C6470')
        .maxLines(1);

      Row({ space: 6 }) {
        Text(`评分 ${this.formatRatingValue(item.rating)}`)
          .fontSize(10)
          .fontColor('#7C6470');
        Text(item.simpleLanguage.length > 0 ? item.simpleLanguage : '语言未知')
          .fontSize(10)
          .fontColor('#9A7D8A')
          .maxLines(1);
      }

      if (item.simpleTags.length > 0) {
        Text(item.simpleTags.slice(0, 4).join('  '))
          .fontSize(10)
          .fontColor('#7C6470')
          .maxLines(2);
      }

      Text(item.posted.length > 0 ? item.posted : '未知日期')
        .fontSize(10)
        .fontColor('#9A7D8A')
        .maxLines(1);
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.onOpenItem(item);
    });
  }

  build() {
    if (this.items.length === 0) {
      Text(this.emptyText)
        .width('100%')
        .fontSize(13)
        .fontColor('#6F5964')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8);
    } else {
      WaterFlow() {
        ForEach(this.items, (item: NativeGallerySummary) => {
          FlowItem() {
            this.GalleryCard(item);
          }
          .width('100%');
        }, (item: NativeGallerySummary) => this.itemKey(item));
      }
      .width('100%')
      .height(this.contentHeight())
      .columnsTemplate(this.columnsTemplate())
      .columnsGap(FAVORITE_WATERFALL_COLUMN_GAP)
      .rowsGap(FAVORITE_WATERFALL_ROW_GAP)
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        this.updateContainerWidth(newValue.width);
      })
      .edgeEffect(EdgeEffect.Spring)
      .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST });
    }
  }
}

@Component
export struct FavoriteGalleryPage {
  @Prop items: NativeGallerySummary[] = [];
  @Prop loading: boolean = false;
  @Prop loadingMessage: string = '正在加载收藏...';
  @Prop error: string = '';
  @Prop emptyText: string = '暂无收藏数据。下拉刷新当前收藏。';
  @Prop itemKeyPrefix: string = 'favorite';
  @Prop firstEnabled: boolean = false;
  @Prop prevEnabled: boolean = false;
  @Prop nextEnabled: boolean = false;
  @Prop lastEnabled: boolean = false;
  @Prop imageVersion: number = 0;
  imageUrlForItem: FavoriteGalleryImageResolver = (item: NativeGallerySummary): string => item.thumb;
  categoryColorForItem: FavoriteGalleryCategoryColorResolver = (_category: string): string => '#607D8B';
  formatRatingValue: FavoriteGalleryRatingFormatter = (rating: number): string => {
    return rating > 0 ? rating.toFixed(1) : '暂无';
  };
  transitionIdForItem: FavoriteGalleryTransitionIdResolver = (_item: NativeGallerySummary): string => '';
  onOpenItem: FavoriteGalleryOpenHandler = (_item: NativeGallerySummary): void => {};
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

  build() {
    Column({ space: 12 }) {
      this.ErrorBlock();
      if (this.loading && this.items.length === 0) {
        this.LoadingBlock();
      } else {
        FavoriteGalleryWaterfallView({
          items: this.items,
          emptyText: this.emptyText,
          itemKeyPrefix: this.itemKeyPrefix,
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
