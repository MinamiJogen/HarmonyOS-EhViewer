import { uiMaterial } from '@kit.ArkUI';

// Shared material presets follow the system's device performance and light-sense settings.
export const IMMERSIVE_CONTROL_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
  interactive: true,
  lightEffect: {}
});

export const IMMERSIVE_MENU_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THICK
});

export const IMMERSIVE_DIALOG_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.ULTRA_THICK
});

export const IMMERSIVE_SHEET_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.ULTRA_THICK
});

export const IMMERSIVE_SEARCH_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
  colorInvert: true,
  interactive: true,
  lightEffect: {}
});

export const IMMERSIVE_SEARCH_FIELD_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
  colorInvert: true,
  applyShadow: false,
  interactive: true,
  lightEffect: {}
});

export const IMMERSIVE_TOOLBAR_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
  colorInvert: true
});

export const IMMERSIVE_SEGMENT_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
  colorInvert: true,
  interactive: true,
  lightEffect: {}
});

export const IMMERSIVE_DOWNLOAD_SEGMENT_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
  colorInvert: true,
  applyShadow: false,
  interactive: true,
  lightEffect: {}
});

export const IMMERSIVE_RANKING_SEGMENT_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.THIN,
  colorInvert: true,
  applyShadow: false,
  interactive: true,
  lightEffect: {}
});

export const IMMERSIVE_RANKING_CONTROL_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
  materialColor: Color.Transparent,
  applyShadow: false,
  interactive: true,
  lightEffect: {}
});

export const IMMERSIVE_SELECTED_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
  materialColor: '#C86B8C',
  colorInvert: true,
  interactive: true,
  lightEffect: {}
});

export const IMMERSIVE_SEARCH_CHIP_SELECTED_MATERIAL: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
  style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
  materialColor: '#C86B8C',
  colorInvert: true,
  interactive: true,
  lightEffect: {}
});
