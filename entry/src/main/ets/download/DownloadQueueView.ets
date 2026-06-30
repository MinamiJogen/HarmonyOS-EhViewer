import {
  DOWNLOAD_STATUS_DELETED,
  DOWNLOAD_STATUS_DONE,
  DOWNLOAD_STATUS_QUEUED,
  DownloadQueueItem
} from './DownloadModels';

export const DOWNLOAD_VIEW_DOWNLOADED: string = 'downloaded';
export const DOWNLOAD_VIEW_ACTIVE: string = 'active';

export type DownloadQueueCommand = () => void;
export type DownloadQueueTextChange = (value: string) => void;
export type DownloadQueueItemAction = (item: DownloadQueueItem) => void;
export type DownloadQueueItemBooleanResolver = (item: DownloadQueueItem) => boolean;
export type DownloadQueueItemNumberResolver = (item: DownloadQueueItem) => number;
export type DownloadQueueItemStringResolver = (item: DownloadQueueItem) => string;
export type DownloadQueueStringResolver = (value: string) => string;

const DOWNLOAD_WATERFALL_MIN_COLUMNS: number = 2;
const DOWNLOAD_WATERFALL_COLUMN_GAP: number = 10;
const DOWNLOAD_WATERFALL_ROW_GAP: number = 12;
const DOWNLOAD_WATERFALL_PREFERRED_ITEM_WIDTH: number = 176;

@Component
export struct DownloadQueueView {
  @Prop items: DownloadQueueItem[] = [];
  @Prop viewMode: string = DOWNLOAD_VIEW_DOWNLOADED;
  @Prop managerStatus: string = '下载器空闲';
  @Prop downloadRootText: string = '';
  @Prop revision: number = 0;
  @State private containerWidth: number = 0;

  imageUrlForCover: DownloadQueueStringResolver = (value: string): string => value;
  siteDisplayNameForItem: DownloadQueueItemStringResolver = (item: DownloadQueueItem): string => item.site;
  statusLabelForItem: DownloadQueueItemStringResolver = (_item: DownloadQueueItem): string => '等待';
  statusColorForItem: DownloadQueueItemStringResolver = (_item: DownloadQueueItem): string => '#C86B8C';
  progressRatioForItem: DownloadQueueItemNumberResolver = (_item: DownloadQueueItem): number => 0;
  progressTextForItem: DownloadQueueItemStringResolver = (_item: DownloadQueueItem): string => '0 页';
  speedTextForItem: DownloadQueueItemStringResolver = (_item: DownloadQueueItem): string => '--';
  remainingTextForItem: DownloadQueueItemStringResolver = (_item: DownloadQueueItem): string => '--';
  isItemRunning: DownloadQueueItemBooleanResolver = (_item: DownloadQueueItem): boolean => false;

  onViewModeChange: DownloadQueueTextChange = (_value: string): void => {};
  onStartAll: DownloadQueueCommand = (): void => {};
  onPauseAll: DownloadQueueCommand = (): void => {};
  onStartItem: DownloadQueueItemAction = (_item: DownloadQueueItem): void => {};
  onPauseItem: DownloadQueueItemAction = (_item: DownloadQueueItem): void => {};
  onOpenItemDetail: DownloadQueueItemAction = (_item: DownloadQueueItem): void => {};
  onRemoveItem: DownloadQueueItemAction = (_item: DownloadQueueItem): void => {};

  private activeItems(): DownloadQueueItem[] {
    return this.items.filter((item: DownloadQueueItem) =>
      item.status !== DOWNLOAD_STATUS_DONE && item.status !== DOWNLOAD_STATUS_DELETED);
  }

  private activeProgressItems(): DownloadQueueItem[] {
    return this.activeItems();
  }

  private downloadedItems(): DownloadQueueItem[] {
    return this.items.filter((item: DownloadQueueItem) => item.status === DOWNLOAD_STATUS_DONE);
  }

  private clampRatio(value: number): number {
    if (!Number.isFinite(value)) {
      return 0;
    }
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  private progressBaseForItem(item: DownloadQueueItem): number {
    return Math.max(item.total, item.pages, Math.ceil(item.downloaded), 1);
  }

  private totalProgressPages(): number {
    let total = 0;
    for (const item of this.activeProgressItems()) {
      total += this.progressBaseForItem(item);
    }
    return total;
  }

  private totalCompletedPages(): number {
    let total = 0;
    for (const item of this.activeProgressItems()) {
      total += Math.floor(this.clampRatio(this.progressRatioForItem(item)) * this.progressBaseForItem(item));
    }
    return total;
  }

  private totalProgressRatio(): number {
    const total = this.totalProgressPages();
    if (total <= 0) {
      return 0;
    }
    return this.clampRatio(this.totalCompletedPages() / total);
  }

  private totalProgressPercent(): number {
    return Math.round(this.totalProgressRatio() * 100);
  }

  private itemProgressPercent(item: DownloadQueueItem): number {
    return Math.round(this.clampRatio(this.progressRatioForItem(item)) * 100);
  }

  private itemRenderKey(item: DownloadQueueItem): string {
    const displayState = this.isItemRunning(item) ? 'running' : item.status;
    return `${item.site}-${item.gid}-${displayState}`;
  }

  private refreshAwareNumber(value: number): number {
    return this.revision >= 0 ? value : value;
  }

  private refreshAwareText(value: string): string {
    return this.revision >= 0 ? value : value;
  }

  private itemProgressPercentLive(item: DownloadQueueItem): number {
    return this.refreshAwareNumber(this.itemProgressPercent(item));
  }

  private itemStatusLabelLive(item: DownloadQueueItem): string {
    return this.refreshAwareText(this.statusLabelForItem(item));
  }

  private itemStatusColorLive(item: DownloadQueueItem): string {
    return this.refreshAwareText(this.statusColorForItem(item));
  }

  private itemProgressTextLive(item: DownloadQueueItem): string {
    return this.refreshAwareText(this.progressTextForItem(item));
  }

  private itemSpeedTextLive(item: DownloadQueueItem): string {
    return this.refreshAwareText(this.speedTextForItem(item));
  }

  private itemRemainingTextLive(item: DownloadQueueItem): string {
    return this.refreshAwareText(this.remainingTextForItem(item));
  }

  private itemActionTextLive(item: DownloadQueueItem): string {
    const text = item.error.length > 0 ? item.error : (item.lastAction.length > 0 ? item.lastAction : item.queuedAt);
    return this.refreshAwareText(text);
  }

  private itemActionColorLive(item: DownloadQueueItem): string {
    return this.refreshAwareText(item.error.length > 0 ? '#B42318' : '#7C6470');
  }

  private shouldPauseItem(item: DownloadQueueItem): boolean {
    return this.isItemRunning(item) || item.status === DOWNLOAD_STATUS_QUEUED;
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
    return (width - DOWNLOAD_WATERFALL_COLUMN_GAP * (columns - 1)) / columns;
  }

  private columnCount(): number {
    if (this.containerWidth <= 0) {
      return DOWNLOAD_WATERFALL_MIN_COLUMNS;
    }
    let bestColumns = DOWNLOAD_WATERFALL_MIN_COLUMNS;
    let bestDistance = Math.abs(this.itemWidthForColumns(this.containerWidth, bestColumns) -
      DOWNLOAD_WATERFALL_PREFERRED_ITEM_WIDTH);
    const widestUsefulColumns = Math.max(
      DOWNLOAD_WATERFALL_MIN_COLUMNS,
      Math.ceil((this.containerWidth + DOWNLOAD_WATERFALL_COLUMN_GAP) /
        (DOWNLOAD_WATERFALL_PREFERRED_ITEM_WIDTH + DOWNLOAD_WATERFALL_COLUMN_GAP)) + 1
    );
    for (let columns = DOWNLOAD_WATERFALL_MIN_COLUMNS + 1; columns <= widestUsefulColumns; columns++) {
      const distance = Math.abs(this.itemWidthForColumns(this.containerWidth, columns) -
        DOWNLOAD_WATERFALL_PREFERRED_ITEM_WIDTH);
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

  private coverHeight(item: DownloadQueueItem): number {
    if (item.pages > 120) {
      return 208;
    }
    if (item.pages > 80) {
      return 188;
    }
    return 154;
  }

  private downloadedCardHeight(item: DownloadQueueItem): number {
    return this.coverHeight(item) + 118;
  }

  private downloadedWaterfallHeight(): number {
    const items = this.downloadedItems();
    const columns = this.columnCount();
    const columnHeights: number[] = [];
    for (let index = 0; index < columns; index++) {
      columnHeights.push(0);
    }
    for (let itemIndex = 0; itemIndex < items.length; itemIndex++) {
      let targetColumn = 0;
      for (let columnIndex = 1; columnIndex < columns; columnIndex++) {
        if (columnHeights[columnIndex] < columnHeights[targetColumn]) {
          targetColumn = columnIndex;
        }
      }
      if (columnHeights[targetColumn] > 0) {
        columnHeights[targetColumn] += DOWNLOAD_WATERFALL_ROW_GAP;
      }
      columnHeights[targetColumn] += this.downloadedCardHeight(items[itemIndex]);
    }
    let total = 0;
    for (let index = 0; index < columnHeights.length; index++) {
      total = Math.max(total, columnHeights[index]);
    }
    return Math.max(180, total);
  }

  @Builder
  private IconButton(
    symbol: Resource,
    label: string,
    backgroundColor: string,
    fontColor: string,
    action: DownloadQueueCommand,
    enabled: boolean = true
  ): void {
    Button() {
      SymbolGlyph(symbol)
        .fontSize(18)
        .fontColor([fontColor]);
    }
    .width(38)
    .height(34)
    .backgroundColor(backgroundColor)
    .borderRadius(8)
    .opacity(enabled ? 1 : 0.42)
    .enabled(enabled)
    .accessibilityText(label)
    .accessibilityDescription(label)
    .onClick(() => {
      action();
    });
  }

  @Builder
  private TextActionButton(symbol: Resource, label: string, primary: boolean, action: DownloadQueueCommand): void {
    Button() {
      Row({ space: 6 }) {
        SymbolGlyph(symbol)
          .fontSize(16)
          .fontColor([primary ? '#FFFFFF' : '#2B2027']);
        Text(label)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(primary ? '#FFFFFF' : '#2B2027')
          .maxLines(1);
      }
      .justifyContent(FlexAlign.Center);
    }
    .layoutWeight(1)
    .height(34)
    .backgroundColor(primary ? '#C86B8C' : '#F3E3EA')
    .borderRadius(8)
    .onClick(() => {
      action();
    });
  }

  @Builder
  private TotalProgressBlock(clickable: boolean): void {
    Column({ space: 8 }) {
      Row() {
        Column({ space: 2 }) {
          Text('下载总进度')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2B2027');
          Text(`${this.activeProgressItems().length} 个任务 · ${this.totalCompletedPages()}/${this.totalProgressPages()} 页`)
            .fontSize(11)
            .fontColor('#7C6470')
            .maxLines(1);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
        Text(`${this.totalProgressPercent()}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#A85474');
      }
      .width('100%');
      Progress({ value: this.totalProgressPercent(), total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(8)
        .color('#C86B8C')
        .backgroundColor('#EEE4E9')
        .borderRadius(4)
        .style({ strokeWidth: 8 });
      if (this.managerStatus.length > 0) {
        Text(this.managerStatus)
          .fontSize(11)
          .fontColor('#6F5964')
          .maxLines(1);
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .border({ width: 1, color: '#F2E6EC' })
    .onClick(() => {
      if (clickable) {
        this.onViewModeChange(DOWNLOAD_VIEW_ACTIVE);
      }
    });
  }

  @Builder
  private DownloadCover(item: DownloadQueueItem): void {
    if (item.cover.length > 0) {
      Image(this.imageUrlForCover(item.cover))
        .width('100%')
        .height(this.coverHeight(item))
        .borderRadius(8)
        .clip(true)
        .objectFit(ImageFit.Cover);
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
  private DownloadedCard(item: DownloadQueueItem): void {
    Column({ space: 8 }) {
      this.DownloadCover(item);
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
        Text(this.siteDisplayNameForItem(item))
          .fontSize(10)
          .fontColor('#FFFFFF')
          .padding({ left: 7, right: 7, top: 3, bottom: 3 })
          .backgroundColor('#A85474')
          .borderRadius(9);
        Text(`${item.total > 0 ? item.total : item.pages}P`)
          .fontSize(11)
          .fontColor('#7C6470');
      }
      Text(item.updatedAt.length > 0 ? item.updatedAt : item.queuedAt)
        .fontSize(10)
        .fontColor('#9A7D8A')
        .maxLines(1);
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .border({ width: 1, color: '#F2E6EC' })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      this.onOpenItemDetail(item);
    });
  }

  @Builder
  private DownloadedWaterfall(): void {
    if (this.downloadedItems().length === 0) {
      Text('还没有已下载画廊。下载完成后会显示在这里。')
        .width('100%')
        .fontSize(13)
        .fontColor('#6F5964')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ width: 1, color: '#F2E6EC' });
    } else {
      WaterFlow() {
        ForEach(this.downloadedItems(), (item: DownloadQueueItem) => {
          FlowItem() {
            this.DownloadedCard(item);
          }
          .width('100%');
        }, (item: DownloadQueueItem) => this.itemRenderKey(item));
      }
      .width('100%')
      .height(this.downloadedWaterfallHeight())
      .columnsTemplate(this.columnsTemplate())
      .columnsGap(DOWNLOAD_WATERFALL_COLUMN_GAP)
      .rowsGap(DOWNLOAD_WATERFALL_ROW_GAP)
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        this.updateContainerWidth(newValue.width);
      })
      .edgeEffect(EdgeEffect.Spring)
      .nestedScroll({ scrollForward: NestedScrollMode.PARENT_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST });
    }
  }

  @Builder
  private ActiveItemCard(item: DownloadQueueItem): void {
    Row({ space: 12 }) {
      if (item.cover.length > 0) {
        Image(this.imageUrlForCover(item.cover))
          .width(58)
          .height(82)
          .borderRadius(6)
          .objectFit(ImageFit.Cover);
      } else {
        Column() {
          Text('无封面')
            .fontSize(10)
            .fontColor('#9A7D8A');
        }
        .width(58)
        .height(82)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F3E3EA')
        .borderRadius(6);
      }

      Column({ space: 7 }) {
        Text(item.title.length > 0 ? item.title : `${item.gid}`)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2B2027')
          .maxLines(2);
        Column({ space: 7 }) {
          Row({ space: 8 }) {
            Text(this.itemStatusLabelLive(item))
              .fontSize(11)
              .fontColor('#FFFFFF')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor(this.itemStatusColorLive(item))
              .borderRadius(6);
            Text(this.itemProgressTextLive(item))
              .fontSize(11)
              .fontColor('#7C6470')
              .maxLines(1);
          }
          .width('100%');
          Progress({ value: this.itemProgressPercentLive(item), total: 100, type: ProgressType.Linear })
            .width('100%')
            .height(8)
            .color(this.itemStatusColorLive(item))
            .backgroundColor('#EEE4E9')
            .borderRadius(4)
            .style({ strokeWidth: 8 });
          Row({ space: 10 }) {
            Text(this.itemSpeedTextLive(item))
              .fontSize(11)
              .fontColor('#7C6470');
            Text(`剩余 ${this.itemRemainingTextLive(item)}`)
              .fontSize(11)
              .fontColor('#7C6470');
          }
          Text(this.itemActionTextLive(item))
            .fontSize(11)
            .fontColor(this.itemActionColorLive(item))
            .maxLines(1);
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start);
        Row({ space: 8 }) {
          this.IconButton(
            this.shouldPauseItem(item) ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'),
            this.shouldPauseItem(item) ? '暂停' : '开始',
            this.shouldPauseItem(item) ? '#F3E3EA' : '#C86B8C',
            this.shouldPauseItem(item) ? '#2B2027' : '#FFFFFF',
            () => {
              if (this.shouldPauseItem(item)) {
                this.onPauseItem(item);
              } else {
                this.onStartItem(item);
              }
            }
          );
          this.IconButton($r('sys.symbol.trash_fill'), '删除', '#FFF3F2', '#B42318', () => {
            this.onRemoveItem(item);
          });
        }
        .width('100%');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .border({ width: 1, color: '#F2E6EC' });
  }

  @Builder
  private DownloadedPage(): void {
    Column({ space: 12 }) {
      this.DownloadedWaterfall();
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private ActivePage(): void {
    Column({ space: 12 }) {
      this.TotalProgressBlock(false);
      Row({ space: 8 }) {
        this.TextActionButton($r('sys.symbol.play_fill'), '全部开始', true, () => {
          this.onStartAll();
        });
        this.TextActionButton($r('sys.symbol.pause_fill'), '全部暂停', false, () => {
          this.onPauseAll();
        });
      }
      .width('100%');

      Text(`目录：${this.downloadRootText}`)
        .fontSize(11)
        .fontColor('#7C6470')
        .maxLines(2);

      if (this.activeItems().length === 0) {
        Text('没有下载中的任务。')
          .width('100%')
          .fontSize(13)
          .fontColor('#6F5964')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .border({ width: 1, color: '#F2E6EC' });
      } else {
        ForEach(this.activeItems(), (item: DownloadQueueItem) => {
          this.ActiveItemCard(item);
        }, (item: DownloadQueueItem) => this.itemRenderKey(item));
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start);
  }

  build() {
    if (this.viewMode === DOWNLOAD_VIEW_ACTIVE) {
      this.ActivePage();
    } else {
      this.DownloadedPage();
    }
  }
}
