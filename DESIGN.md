---
version: alpha
name: MiCut
description: 미쿠와 함께하는 사진을 위한 회색 중심 모바일 카메라
colors:
  primary: '#222222'
  background: '#FFFFFF'
  surface: '#F5F5F5'
  muted: '#707070'
  border: '#E7E7E7'
typography:
  sans:
    fontFamily: 'Noto Sans KR, Malgun Gothic, Apple SD Gothic Neo, sans-serif'
rounded:
  button: '12px'
  card: '14px'
spacing:
  page: '24px'
  gap: '12px'
components:
  button:
    rounded: '12px'
  card:
    rounded: '14px'
---
# MiCut Design System
## Overview
Product register / Operate. Preserve the supplied Figma wireframe, not an invented colorful Miku theme. Korean camera use on mobile; market beyond the supplied Korean UI is unconfirmed. Signature: large dark shutter and a quiet three-item navigation bar. No gradients, decorative shadows, or fake photographs.
Runtime ownership: lib/theme.dart is canonical; this file mirrors its constants and ThemeData. `ink` → primary, `paper` → surface, `muted` → secondary text, `line` → border; appTheme → buttons, typography, app bars, feedback. Figma exact font/variable inspection is unavailable in anonymous viewing; sizes are implementation estimates from the rendered reference.
## Colors
White page, soft gray task tiles, near-black text and primary controls. Dark capture surface makes the camera preview primary. Errors include text and symbols; never rely on color alone.
## Typography
Korean-capable OS fallback stack. MiCut heading 26/bold; section titles 17/semibold; body defaults to Flutter typography, short metadata 11–12. No external runtime font download.
## Layout
24px side gutters, two-column gallery and collection, 12px grid gap. SafeArea for all bottom controls. Phone shell max 480px on desktop; layouts shrink to phone width. Workflow media uses remaining height; long feedback scrolls inside a bounded footer.
## Elevation & Depth
Flat surfaces. Native Material dialog elevation only when user confirmation is required. Fixed media footprint during loading.
## Shapes
12px buttons and photo thumbnails, 14px home tiles, circular shutter and camera nav button.
## Components
ThemeData owns buttons, app bar, toast, icon target geometry. Material controls own keyboard/focus/disabled states. EmptyView and Notice own shared empty and persistent failure feedback. Gallery and detail share ResultImage. Fullscreen overlays remain inside the same constrained Navigator.
Buttons have 52px minimum height; icon controls at least 48px. Busy states disable duplicate mutation actions. Progress is indeterminate; no fictional percentage. Native transitions respect platform reduced-motion settings. Camera grid is an actual framing aid.
## Do's and Don'ts
- Keep the capture flow primary and navigation labeled.
- Retain retryable errors until explicitly recovered/discarded.
- Do not show acquired cards, pose assets, or successful saves without evidence.
- Do not turn the phone UI into a marketing page at wide widths.


## User correction — 2026-11-03
Only reproduce elements observed in the supplied Figma. Do not introduce demo badges, tutorial buttons, sparkle illustrations, collection locks, extra taglines, or preparation notices. Development state belongs in documentation/tests. Empty image assets use Figma's plain gray placeholders; unimplemented cards must not fabricate acquisition dates. API failures and platform permission errors appear only when triggered.

Camera and confirmation use the same 3:4 frame; changing footer height must not stretch the photo. Camera JPEGs are centered crops matching this viewport, while album photos keep their own ratio.
