import {
  createEmptyNativeGalleryDetail,
  EhTagTranslator,
  NativeGalleryDetail,
  NativeTagGroup
} from '../../ehviewer/EhNative';

export type GalleryStringResolver = (value: string) => string;
export type GalleryRatingFormatter = (rating: number) => string;
export type GalleryAction = () => void;
export type GalleryTagAction = (namespace: string, tag: string) => void;
export type GalleryMetaLineFormatter = (label: string, value: string) => string;

@Component
export struct GalleryDetailPage {
  @Prop detail: NativeGalleryDetail = createEmptyNativeGalleryDetail();
  @Prop detailRevision: number = 0;
  @Prop metaLanguage: string = '';
  @Prop metaVisible: string = '';
  @Prop metaFileSize: string = '';
  @Prop metaFavoriteCount: number = 0;
  @Prop metaTorrentCount: number = 0;
  @Prop tagSearchTransitionQuery: string = '';
  @Prop imageVersion: number = 0;
  @Prop coverTransitionId: string = '';
  coverUrlFor: GalleryStringResolver = (value: string): string => value;
  categoryColorFor: GalleryStringResolver = (_value: string): string => '#607D8B';
  formatRatingValue: GalleryRatingFormatter = (rating: number): string => {
    return rating > 0 ? rating.toFixed(1) : '暂无';
  };
  metaLineFor: GalleryMetaLineFormatter = (label: string, value: string): string => `${label}：${value}`;
  onRead: GalleryAction = (): void => {};
  onOpenUploader: GalleryAction = (): void => {};
  onOpenParent: GalleryAction = (): void => {};
  onTagSearch: GalleryTagAction = (_namespace: string, _tag: string): void => {};

  @BuilderParam actionsContent: () => void = this.EmptySlot;
  @BuilderParam statusContent: () => void = this.EmptySlot;
  @BuilderParam favoritePanelContent: () => void = this.EmptySlot;
  @BuilderParam ratingPanelContent: () => void = this.EmptySlot;
  @BuilderParam torrentPanelContent: () => void = this.EmptySlot;
  @BuilderParam archivePanelContent: () => void = this.EmptySlot;
  @BuilderParam commentsContent: () => void = this.EmptySlot;
  @BuilderParam previewPagerContent: () => void = this.EmptySlot;
  @BuilderParam previewStripContent: () => void = this.EmptySlot;
  @BuilderParam metadataContent: () => void = this.MetadataBlock;

  @Builder
  private EmptySlot(): void {
  }

  private resolvedCoverUrl(): string {
    this.imageVersion;
    return this.coverUrlFor(this.detail.cover);
  }

  private tagSearchTransitionId(namespace: string, tag: string): string {
    const query = `${namespace}:${tag}`;
    return this.tagSearchTransitionQuery === query ? `tag-search:${query}` : '';
  }

  @Builder
  private CoverBlock(): void {
    if (this.detail.cover.length > 0) {
      Image(this.resolvedCoverUrl())
        .width(104)
        .height(148)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)
        .clip(true)
        .backgroundColor('#FAFAFA')
        .geometryTransition(this.coverTransitionId)
        .transition(TransitionEffect.OPACITY)
        .onClick(() => {
          this.onRead();
        });
    } else {
      Column() {
        Text('无封面')
          .fontSize(12)
          .fontColor('#9A7D8A');
      }
      .width(104)
      .height(148)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#F3E3EA')
      .borderRadius(8);
    }
  }

  @Builder
  private HeaderBlock(): void {
    Row({ space: 14 }) {
      this.CoverBlock();

      Column({ space: 8 }) {
        Text(this.detail.title.length > 0 ? this.detail.title : `${this.detail.gid}`)
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2B2027')
          .maxLines(4);
        if (this.detail.titleJpn.length > 0 && this.detail.titleJpn !== this.detail.title) {
          Text(this.detail.titleJpn)
            .fontSize(13)
            .fontColor('#7C6470')
            .maxLines(2);
        }
        Row({ space: 8 }) {
          Text(this.detail.categoryLabel.toUpperCase())
            .fontSize(11)
            .fontColor('#FFFFFF')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .backgroundColor(this.categoryColorFor(this.detail.categoryLabel))
            .borderRadius(4);
          Text(`${this.detail.pages}P`)
            .fontSize(12)
            .fontColor('#6F5964');
        }
        Text(this.detail.uploader.length > 0 ? this.detail.uploader : '未知上传者')
          .fontSize(12)
          .fontColor('#4E3A45')
          .maxLines(1)
          .onClick(() => {
            this.onOpenUploader();
          });
        Text(`评分 ${this.formatRatingValue(this.detail.rating)} (${this.detail.ratingCount})`)
          .fontSize(12)
          .fontColor('#7C6470');
        Text(this.detail.posted.length > 0 ? this.detail.posted : '未知日期')
          .fontSize(11)
          .fontColor('#9A7D8A');
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8);
  }

  @Builder
  private MetadataLine(label: string, value: string): void {
    Row({ space: 8 }) {
      Text(label)
        .width(48)
        .fontSize(12)
        .fontColor('#9A7D8A')
        .maxLines(1);
      Text(value.length > 0 ? value : '-')
        .layoutWeight(1)
        .fontSize(13)
        .fontColor('#4E3A45')
        .maxLines(1);
    }
    .width('100%')
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private MetadataBlock(): void {
    Column({ space: 7 }) {
      this.MetadataLine('语言', this.metaLanguage);
      this.MetadataLine('可见性', this.metaVisible);
      this.MetadataLine('大小', this.metaFileSize);
      this.MetadataLine('收藏数', `${this.metaFavoriteCount}`);
      this.MetadataLine('Torrent', this.metaTorrentCount > 0 ? `${this.metaTorrentCount}` : '0');
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private InfoActionBlock(): void {
    Row({ space: 12 }) {
      this.metadataContent();
      if (this.detailRevision % 2 === 0) {
        this.actionsContent();
      } else {
        this.actionsContent();
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(VerticalAlign.Center);
  }

  @Builder
  private TagsBlock(): void {
    Column({ space: 10 }) {
      Text('标签')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2B2027');
      if (this.detail.tagGroups.length === 0) {
        Text('暂无标签')
          .fontSize(13)
          .fontColor('#A85474')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 8 });
      } else {
        ForEach(this.detail.tagGroups, (group: NativeTagGroup) => {
          Row({ space: 8 }) {
            Text(EhTagTranslator.translateNamespace(group.name))
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .backgroundColor('#A85474')
              .borderRadius(6)
              .maxLines(1);
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(group.tags, (tag: string) => {
                Text(EhTagTranslator.translateTag(group.name, tag))
                  .fontSize(11)
                  .fontColor('#4E3A45')
                  .padding({ left: 8, right: 8, top: 5, bottom: 5 })
                  .margin({ right: 6, bottom: 6 })
                  .backgroundColor('#F3E3EA')
                  .borderRadius(6)
                  .maxLines(1)
                  .geometryTransition(this.tagSearchTransitionId(group.name, tag))
                  .onClick(() => {
                    this.onTagSearch(group.name, tag);
                  });
              }, (tag: string) => `${group.name}:${tag}`);
            }
            .layoutWeight(1);
          }
          .width('100%')
          .alignItems(VerticalAlign.Top);
        }, (group: NativeTagGroup) => `${group.name}-${group.tags.length}`);
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .alignItems(HorizontalAlign.Start);
  }

  build() {
    Column({ space: 12 }) {
      this.HeaderBlock();
      this.InfoActionBlock();
      this.TagsBlock();
      this.commentsContent();
      this.previewStripContent();
    }
    .width('100%')
    .opacity(this.detailRevision >= 0 ? 1 : 1);
  }
}
