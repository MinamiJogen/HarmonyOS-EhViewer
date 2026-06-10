export interface LocalGalleryRecord {
  gid: number;
  token: string;
  title: string;
  titleJpn: string;
  cover: string;
  detailUrl: string;
  site: string;
  uploader: string;
  categoryLabel: string;
  posted: string;
  pages: number;
  language: string;
  rating: number;
}

export interface HistoryItem extends LocalGalleryRecord {
  visitedAt: string;
}
