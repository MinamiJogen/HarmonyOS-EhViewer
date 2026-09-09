import {
  DOWNLOAD_STATUS_DELETED,
  DOWNLOAD_STATUS_DONE,
  DOWNLOAD_STATUS_DOWNLOADING,
  DOWNLOAD_STATUS_FAILED,
  DOWNLOAD_STATUS_PAUSED,
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
  @Prop activeContentStartOffset: number = 0;
  @Prop activeContentEndOffset: number = 0;
  @Prop activeLoading: boolean = false;
  activeScroller: Scroller = new Scroller();
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

  private itemActionColorLive(item: DownloadQueueItem): ResourceColor {
    return this.refreshAwareText(item.error).length > 0 ?
      $r('sys.color.ohos_id_color_warning') : $r('sys.color.font_secondary');
  }

  private shouldPauseItem(item: DownloadQueueItem): boolean {
    return this.refreshAwareNumber(this.isItemRunning(item) || item.status === DOWNLOAD_STATUS_QUEUED ? 1 : 0) === 1;
  }

  private itemCommandLabel(item: DownloadQueueItem): string {
    if (this.shouldPauseItem(item)) {
      return '暂停';
    }
    if (item.status === DOWNLOAD_STATUS_FAILED) {
      return '重试';
    }
    if (item.status === DOWNLOAD_STATUS_PAUSED || item.status === DOWNLOAD_STATUS_DOWNLOADING ||
      item.downloaded > 0) {
      return '继续';
    }
    return '开始';
  }

  private canStartAll(): boolean {
    return this.refreshAwareNumber(
      this.activeItems().some((item: DownloadQueueItem) => !this.isItemRunning(item)) ? 1 : 0) === 1;
  }

  private canPauseAll(): boolean {
    return this.activeItems().some((item: DownloadQueueItem) => this.shouldPauseItem(item));
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
  private GroupHeader(title: string): void {
    Text(title)
      .width('100%')
      .fontSize(14)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_secondary'))
      .padding({ left: 16, right: 16, top: 12, bottom: 12 });
  }

  @Builder
  private TextActionButton(symbol: Resource, label: string, primary: boolean,
    action: DownloadQueueCommand, enabled: boolean = true): void {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 8 }) {
        SymbolGlyph(symbol)
          .fontSize(18)
          .fontColor([primary ? '#FFFFFF' : $r('sys.color.font_primary')]);
        Text(label)
          .layoutWeight(1)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(primary ? '#FFFFFF' : $r('sys.color.font_primary'))
          .textAlign(TextAlign.Center);
      }
      .width('100%')
      .justifyContent(FlexAlign.Center);
    }
    .layoutWeight(1)
    .constraintSize({ minHeight: 48 })
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(primary ? '#C86B8C' : $r('sys.color.comp_background_tertiary'))
    .borderRadius(12)
    .enabled(enabled)
    .accessibilityText(label)
    .onClick(() => {
      action();
    });
  }

  @Builder
  private TotalProgressBlock(): void {
    Column({ space: 14 }) {
      Row({ space: 12 }) {
        Column({ space: 6 }) {
          Text('下载总进度')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'));
          Text(this.refreshAwareText(
            `${this.activeProgressItems().length} 个任务 · ${this.totalCompletedPages()}/${this.totalProgressPages()} 页`))
            .fontSize(13)
            .fontColor($r('sys.color.font_secondary'));
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
        Text(this.refreshAwareText(`${this.totalProgressPercent()}%`))
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#A85474');
      }
      .width('100%')
      .alignItems(VerticalAlign.Center);
      Progress({ value: this.refreshAwareNumber(this.totalProgressPercent()), total: 100, type: ProgressType.Linear })
        .width('100%')
        .color('#C86B8C')
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .style({ strokeWidth: 8 })
        .accessibilityText(this.refreshAwareText(`下载总进度 ${this.totalProgressPercent()}%`));
      if (this.managerStatus.length > 0) {
        Text(this.managerStatus)
          .width('100%')
          .fontSize(13)
          .fontColor($r('sys.color.font_secondary'));
      }
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start);
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
  private ActiveItemHeader(item: DownloadQueueItem): void {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 14 }) {
        if (item.cover.length > 0) {
          Image(this.imageUrlForCover(item.cover))
            .width(64)
            .height(88)
            .borderRadius(10)
            .clip(true)
            .objectFit(ImageFit.Cover);
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.waveform_folder_fill'))
              .fontSize(24)
              .fontColor([$r('sys.color.font_secondary')]);
          }
          .width(64)
          .height(88)
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .borderRadius(10);
        }
        Column({ space: 8 }) {
          Text(item.title.length > 0 ? item.title : `${item.gid}`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis });
          Text(this.siteDisplayNameForItem(item))
            .fontSize(12)
            .fontColor($r('sys.color.font_secondary'));
          Text(this.itemStatusLabelLive(item))
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.itemStatusColorLive(item));
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(14)
          .fontColor([$r('sys.color.font_secondary')]);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top);
    }
    .width('100%')
    .constraintSize({ minHeight: 88 })
    .padding(0)
    .backgroundColor(Color.Transparent)
    .borderRadius(10)
    .accessibilityText(`查看画廊 ${item.title.length > 0 ? item.title : item.gid}`)
    .onClick(() => {
      this.onOpenItemDetail(item);
    });
  }

  @Builder
  private ActiveItemCard(item: DownloadQueueItem): void {
    Column({ space: 14 }) {
      this.ActiveItemHeader(item);
      Column({ space: 10 }) {
        Row({ space: 12 }) {
          Text(this.itemProgressTextLive(item))
            .layoutWeight(1)
            .fontSize(13)
            .fontColor($r('sys.color.font_secondary'));
          Text(`${this.itemProgressPercentLive(item)}%`)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'));
        }
        .width('100%');
        Progress({ value: this.itemProgressPercentLive(item), total: 100, type: ProgressType.Linear })
          .width('100%')
          .color(this.itemStatusColorLive(item))
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .style({ strokeWidth: 6 })
          .accessibilityText(`下载进度 ${this.itemProgressPercentLive(item)}%`);
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
          Text(`速度 ${this.itemSpeedTextLive(item)}`)
            .fontSize(13)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ right: 16, bottom: 4 });
          Text(`剩余 ${this.itemRemainingTextLive(item)}`)
            .fontSize(13)
            .fontColor($r('sys.color.font_secondary'))
            .margin({ bottom: 4 });
        }
        .width('100%');
        if (this.itemActionTextLive(item).length > 0) {
          Text(this.itemActionTextLive(item))
            .width('100%')
            .fontSize(13)
            .fontColor(this.itemActionColorLive(item))
            .copyOption(CopyOptions.LocalDevice);
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start);
      Row({ space: 12 }) {
        this.TextActionButton(
          this.shouldPauseItem(item) ? $r('sys.symbol.pause_fill') : $r('sys.symbol.play_fill'),
          this.refreshAwareText(this.itemCommandLabel(item)),
          !this.shouldPauseItem(item),
          () => {
            if (this.shouldPauseItem(item)) {
              this.onPauseItem(item);
            } else {
              this.onStartItem(item);
            }
          }
        );
        Button('移除')
          .constraintSize({ minWidth: 80, minHeight: 48 })
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .fontSize(15)
          .fontColor($r('sys.color.ohos_id_color_warning'))
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .borderRadius(12)
          .accessibilityText(`移除下载任务及本地文件 ${item.title}`)
          .onClick(() => {
            this.onRemoveItem(item);
          });
      }
      .width('100%');
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private ActiveEmptyState(): void {
    Column({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.waveform_folder_fill'))
        .fontSize(40)
        .fontColor([$r('sys.color.font_secondary')]);
      Text('暂无下载任务')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'));
      Text('添加下载后，可在这里查看进度和管理任务。')
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Center);
      if (this.downloadedItems().length > 0) {
        Button('查看已下载')
          .constraintSize({ minHeight: 48 })
          .fontSize(15)
          .fontColor('#A85474')
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .onClick(() => {
            this.onViewModeChange(DOWNLOAD_VIEW_DOWNLOADED);
          });
      }
    }
    .width('100%')
    .constraintSize({ minHeight: 200 })
    .padding(24)
    .justifyContent(FlexAlign.Center);
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
    Column() {
      List({ space: 16, scroller: this.activeScroller }) {
        if (this.activeLoading) {
          ListItem({ style: ListItemStyle.CARD }) {
            Column({ space: 12 }) {
              LoadingProgress()
                .width(32)
                .height(32);
              Text('正在加载下载任务...')
                .fontSize(14)
                .fontColor($r('sys.color.font_secondary'));
            }
            .width('100%')
            .constraintSize({ minHeight: 160 })
            .padding(24)
            .justifyContent(FlexAlign.Center);
          }
          .height(undefined);
        } else {
          if (this.activeItems().length > 0) {
            ListItemGroup({ header: this.GroupHeader('下载概览'), style: ListItemGroupStyle.CARD }) {
              ListItem({ style: ListItemStyle.CARD }) {
                this.TotalProgressBlock();
              }
              .height(undefined);
              ListItem({ style: ListItemStyle.CARD }) {
                Row({ space: 12 }) {
                  this.TextActionButton($r('sys.symbol.play_fill'), '全部开始', true, () => {
                    this.onStartAll();
                  }, this.canStartAll());
                  this.TextActionButton($r('sys.symbol.pause_fill'), '全部暂停', false, () => {
                    this.onPauseAll();
                  }, this.canPauseAll());
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 4, bottom: 16 });
              }
              .height(undefined);
            }
            ListItemGroup({
              header: this.GroupHeader(`下载任务 · ${this.activeItems().length}`),
              style: ListItemGroupStyle.CARD
            }) {
              ForEach(this.activeItems(), (item: DownloadQueueItem) => {
                ListItem({ style: ListItemStyle.CARD }) {
                  this.ActiveItemCard(item);
                }
                .height(undefined);
              }, (item: DownloadQueueItem) => this.itemRenderKey(item));
            }
            .divider({ strokeWidth: 0.5, color: $r('sys.color.comp_divider'), startMargin: 16, endMargin: 16 });
          } else {
            ListItem({ style: ListItemStyle.CARD }) {
              this.ActiveEmptyState();
            }
            .height(undefined);
          }
          if (this.downloadRootText.length > 0) {
            ListItemGroup({ header: this.GroupHeader('保存位置'), style: ListItemGroupStyle.CARD }) {
              ListItem({ style: ListItemStyle.CARD }) {
                Text(this.downloadRootText)
                  .width('100%')
                  .fontSize(13)
                  .fontColor($r('sys.color.font_secondary'))
                  .copyOption(CopyOptions.LocalDevice)
                  .padding(16);
              }
              .height(undefined);
            }
          }
        }
      }
      .width('100%')
      .constraintSize({ maxWidth: 840 })
      .height('100%')
      .padding({ left: 12, right: 12 })
      .contentStartOffset(this.activeContentStartOffset)
      .contentEndOffset(this.activeContentEndOffset)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring);
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'));
  }

  build() {
    if (this.viewMode === DOWNLOAD_VIEW_ACTIVE) {
      this.ActivePage();
    } else {
      this.DownloadedPage();
    }
  }
}
