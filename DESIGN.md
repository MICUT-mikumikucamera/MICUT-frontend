# MiCut design context

## Overview

Canonical product design evidence: [user-supplied design system](docs/design-system.md), then the Figma canvas at node 176:4374 observed through the browser on 2026-11-06. Earlier scaffold moodboard interpretation is not the final design. This document describes the current migration; it does not claim exact Figma variable export or full visual parity.

Mobile Korean camera application. Home, gallery, photo/card details and capture confirmation/processing/result use white surfaces. Camera chrome is black, guide is charcoal, and collection is dark. Capture info footers remain white. Avoid speculative HUD/REC labels, glow, badges and fabricated collection acquisition.

## Colors

Primitive gray values and semantic mappings are exact values from the supplied system. White page is #FEFEFE, inverse #09090B, secondary background #F4F4F5, placeholder #52525B. Text subtle is #71717A; icon subtle is independently #D4D4D8. Role aliases remain separate even where values match.

Brand palette values, primary gradients and danger red are provisional. The browser reference shows pale cyan horizontal primary CTA, a radial cyan capture navigation button, cyan/pink home tiles and red destructive actions. It does not establish exact hex values or stop positions. Existing cyan/pink palette values are retained as implementation approximations; danger uses provisional #C62828 instead of the old pink. Do not describe these as read from Figma variables.

## Typography

Pretendard 400/500/600/700 is bundled locally. Registered heading, body, label and detail styles follow docs/design-system.md. Tracking is fontSize × -0.02. Heading/label/detail use 1.4 line height; body24/20 use 1.4 and body18/16/14 use 1.5. Legacy aliases map to documented roles. DungGeunMo is not bundled: display acquisition animation remains incomplete, and the legacy display alias is explicitly not its replacement.

## Layout

Default page padding and content gap are 20. Primitive spacing: 0/2/4/6/8/10/12/16/20/24/32. Modal padding20, modal gap16, CTA/card gap8, navigation icon-label gap4. Footer controls respect SafeArea and small viewports. Existing control height52, navigation height64 and shutter76 remain implementation geometry pending exact component inspection.

## Elevation & Depth

No decorative glow. Compatibility shadow arrays are empty. Native dialogs preserve interaction and focus behavior.

## Shapes

Registered radius10/12/16/20/24. Legacy small radius maps to10; medium12; large16; extra large24. Component-specific radius assignments require matching the actual Figma component.

## Components

Runtime ownership: lib/core/theme/colors.dart owns Primitive and Semantic colors plus provisional gradients; spacing.dart owns spacing/radius; typography.dart owns TextStyles; theme.dart adapts these to Material ThemeData. Shared widgets consume these owners. Docs/design-system.md is the user-authored source specification; this document tracks runtime decisions and unresolved values.

The common controls correspond to CTA1/CTA2, TopBar/TabBar, Photo/CollectionCard, ratio/flash/timer/camera, info/modal/loading. Reuse shared controls and existing routing rather than duplicating style definitions per screen. Real photos and acquisition state remain data-driven.

## Do's and Don'ts

- Use role-specific Semantic variables and documented TextStyles.
- Keep danger red distinct from secondary brand pink.
- Preserve retry, disabled, permission-error and empty states.
- Do not use screenshot images as app assets, fabricate photography, redraw unavailable brand art, or imply mock results are real server acquisitions.
- Unresolved: exact brand palette/semantic mappings, gradient stops, static Figma assets, component variants/geometry and special display font. Browser screenshots guide layout but are not a variable export.

Home tile foreground temporarily uses text/default for readable contrast on provisional brand fills; the reference uses light foreground on its original artwork. Reconcile with the actual tile assets and verified semantic pairing when available.

## User restriction — 2026-11-06
Only Figma-confirmed UI/copy and explicitly requested controls are authorized. Do not add browser-specific labels, unsolicited snackbars, helper copy, counters or preview decorations. Retain nonvisual failure handling without displaying unapproved copy.

## 2026-11-06 source-only correction
DungGeunMo is now bundled from the author's public-domain TTF distribution; previous notes about its absence are superseded. Home feature foreground is white per source. Camera permission and unsaved exit dialogs follow observed source copy. Settings contains only the three observed rows; unprovided destinations and memo editor designs remain unimplemented, with no invented dialogs or links. Original artwork export still fails access checks; do not draw substitutes or claim exact visual parity. Brand values and unmeasured geometry remain unresolved.

## Browser export reconciliation — 2026-11-06

The user authorized browser downloads after the connector denied access. The browser exported `../figma-source/미컷.fig` and a 60-page `../figma-source/미컷.pdf`. The local file decoded to 3,615 nodes; `../figma-source/document.json` retains source values and `screen-tree.txt` records the screen hierarchy. This source supersedes earlier claims that original assets and geometry were unavailable.

Runtime owners remain `core/theme` and shared controls. Confirmed changes: danger #EF4444; solid primary #67E8F9; CTA1 57px / radius20; CTA2 50px / radius16 / label18-semibold; capture TabBar button 50px circle; info text-to-actions gap24 and paired action gap12. CTA gradient endpoints are #22D3EE and #88EFFF in exported node177:6693. Native safe areas adapt to the device; mock status bars are never painted into the app.

Assets in `assets/figma-export`: home background components from PDF pages51/52 (335×180 and335×160), locked pose artwork from page60 (295×320), and logo directly exported at4x from node206:7934. Only standalone graphic components were rasterized; screen screenshots are reference-only. Home text, buttons, photos and navigation remain live Flutter widgets. User photos and collected-card status remain data-driven.

Collection card proportions are160×207.018 and source alternating rotations are±2 degrees. Photo detail uses the source's taller action area; capture photos fill their design slot. Layout tests cover320/390px and text scales1/1.5. Unverified parity must not be described as complete: Material icon replacements and some screen-specific alignment still require further comparison with the exported reference.

## User corrections — 2026-11-07

User-requested centering supersedes source offsets: home logo/settings and camera top/bottom actions are vertically centered; icon feedback and glyph share a center. MiCutIconButton owns the 48px circular icon interaction. MiCutTabBar owns equal full-height feedback regions and enough content space for the capture circle and label, plus one native bottom inset.

Capture frames fit their selected ratio inside available space; CaptureView uses contain so displayed crops/results are never cropped again by the layout. CaptureDraft owns full-field orientation-normalized upload bytes and independent crop preview. See docs/capture-original-contract.md for the explicit multipart contract; server implementation remains separate.

Camera options use CaptureOptionsRail: a vertical original-icon menu centered in the photo viewport at the same x coordinate as its triggers. The visible background is 40px wide, black at 60% opacity; 24px icons have 8px horizontal and vertical visual inset; menu touch targets remain 48×40px and the background has a 20px capsule radius. Collapsed triggers remain 48×48px. Selected icons use cyan200. Opening fades other triggers out, moves the chosen trigger into its selected option slot, then reveals the list. Closing reverses that order: list hides, trigger returns, others reappear. Duration is 420ms; reduced motion resolves immediately. Selection/outside/Escape/back dismiss; existing flash/timer/ratio choices and unavailable states remain.

Verification for this change is automated tests and web build only. The user explicitly owns browser and physical-device visual verification.

Home background correction: figma-source/fix-home-background-blend.py regenerates both background PNGs from explicit source gradients (206:7720 / 176:4762), the original decorative image hash ab618f842319f6dfdd6ea498a2947ee9bb553742, and its 40% LINEAR_DODGE paint. This replaces PDF rasterization of that blend. The source inner-shadow color/opacity and rounded-edge mask are retained in raster compositing. Re-running the generator yields identical asset hashes; no screen screenshot is used as a runtime asset.





The ratio menu adds 4px optical padding at each vertical end for the square corner marks against the capsule curve; icon row spacing, centers, and other option menus are unchanged.
Home header centers logo/settings within the full 69px space above the first card (51px header plus former 18px bottom gap); the card position stays fixed.
Home settings button is offset 4px right of the feature-card edge per user adjustment (16px right inset; card padding remains 20px). The icon remains centered inside its 48px interaction circle. Collection uses available sliver width to compute ceil((width+15)/(200+15)) columns; card layout width never exceeds 200px, with original 15px gaps and 160/207 proportions.
Bottom navigation is icon-only: labels remain accessible semantics but are not painted. Each equal-width tab centers its icon in a 70px content area above the native bottom inset; the 50px capture circle remains. Hover/pressed regions still cover equal full tab rectangles.



Home logo left visible margin now matches the settings gear visible right margin: 30.25px (16px button inset + 12px centered-icon inset + 2.25px transparent PNG inset). The settings target position and card margins remain unchanged.
Latest optical adjustment: move only the home logo 4px left, to a 26.25px left margin. Settings button retains its 16px right inset.


## Figma refresh — 2026-11-18

Source: browser-authorized export `../figma-source/review-2026-11-18/latest.fig`, decoded document and normalized diff. Eight new auth states; existing home, guide, processing, new collection and empty gallery art changes. Original standalone graphics exported from Figma are runtime assets; screenshots are verification only.

Canonical ownership: MikuIllustration owns four source characters; MiCutLoading owns reduced-motion-aware processing animation; NewCollectionOverlay owns one-shot dismissal after three seconds. Shared MiCutButton adds white tertiary/leading graphic support. Auth screens reuse shared typography, colors, icons and buttons; OnboardingPage owns scrollable content and bottom action. Nickname rules own grapheme-aware 2–20 validation and counter; this explicit user decision supersedes Figma's conflicting 0/10 counter. Existing user corrections above remain authoritative.

Auth UI preview is explicitly enabled with MICUT_AUTH_PREVIEW. Default entry remains home. No production authentication is simulated: AuthGateway is unconfigured until a real contract exists, legal links require HTTPS configuration, and session-expired is a presentation route awaiting real session integration. No legal copy was invented. Browser app verification remains user-owned; widget-rendered screenshots, automated workflows and web compilation are the validation scope.

## UI-only authentication preview — 2026-11-19

BrowserPreview now starts at login by default when MICUT_REAL_API is false; MICUT_AUTH_PREVIEW=false restores home entry. Native/default production entry is unchanged. Existing login/nickname/consent screens remain canonical. Preview full-view actions open LegalPreviewScreen, reusing OnboardingPage and shared tokens/buttons. It explicitly presents unavailable document content without inventing legal terms, calling external URLs, or persisting consent. Returning preserves the consent screen state. Actual production legal links still require configured HTTPS URLs.

## Login appearance correction — 2026-11-19

The user clarified that the dark/light Figma login frames are device appearance variants, not animation keyframes. LoginScreen now reads MediaQuery.platformBrightnessOf directly, selecting background artwork, gradient and foreground text on the first frame and when the system preference changes. Removed the 800ms timer and appearance transition; reduced motion no longer forces light mode. This overrides earlier dark-to-light interpretation. Other screens retain their existing styling.

## Responsive copy, consent and home cards — 2026-11-19

User corrections: onboarding headings/descriptions wrap between Korean words using shared WordWrapText; removed forced title line breaks and kept the nickname title's music mark with its preceding word. Original readable copy remains the accessibility label. TermsScreen adds an all-consent checkbox derived from both individual values; it toggles both and follows individual changes. Home feature cards reserve separate responsive text/art columns with positive padding and contain-fit artwork, replacing negative image offsets and overlap. Existing header/card margins and navigation are retained. These user corrections supersede earlier overlapping home artwork layout.

## Figma alignment restoration and maximum artwork — 2026-11-19

Reviewed original nodes 402:2542 (terms), 402:1274 (nickname), 402:2500 (login). Terms uses #F4F4F5 rounded rows (radius20, minimum height54, padding16, gap12), text and inline underlined full-view link on the left, 20px original check on the right (#A1A1AA unchecked / #22D3EE checked). Replaced the incorrect default CheckboxListTile layout. Explicit source title line breaks restored while WordWrapText still prevents syllable splits. User-requested all-consent follows the two source rows, preserving their order and placement. Source header toolbar51, title/description gap12, nickname content gap70 and terms gap80 restored. Bottom button stays 32px from bottom where safe-area permits. Login source tagline24 and logo-to-tagline gap20 restored.

Home artwork no longer uses a percentage width cap: it occupies the maximum square that fits the card height minus 8px top/bottom, reserving measured minimum word width, 12px text gap and an 8px right inset. Text keeps a 20px left inset. This supersedes the earlier small artwork correction without reintroducing clipping/overlap.

## 2026-11-20 remaining screen alignment audit

Reference: the saved November 18 Figma export, not a fresh server revision. Compared capture guide/camera/confirmation/processing/failure/network/result/saved, gallery/empty/edit/delete, photo detail, collection/card detail/story, settings and shared dialogs with source geometry. Prior explicit user corrections remain authoritative.

| Area | Result |
| --- | --- |
| Nickname (402:2716 / 402:2726) | Removed Material floating label and separate error/counter footer. Counter is beside the input above the underline; success/error feedback shares one position 8px below the line, 16px icon + 6px gap, gray 14px text. Error underline uses source #991B1B. 2–20 and composition validation retained. |
| Result header | Removed topCenter from share action, matching close action center. |
| Gallery header | Removed the old -3.5px title translation; title and edit action now share a center. |
| Settings/shared back button | Explicit zero padding and centered 24px asset; title and icon centers tested. |
| Empty gallery (176:4939) | Center compensation now uses the user-selected 70px tab content plus real bottom inset, replacing stale source 83px bar assumption. Source art/text/button gaps retained. |
| Photo detail (176:4797) | Restored source action group vertical offset within the existing footer; no image fitting change. |
| Card detail (176:4859) | Date uses source 18px line height, removing 6px extra before memo. Photo carousel and 24/32/12px gaps retained. |
| Processing (432:3468) | Character centered on the viewport (source y406 at 812px), rather than the photo area. Motion preserved. |
| New collection (177:7350) | Restored title frame top130/812 of viewport and source card gap. Scroll adaptation and three-second dismissal retained. |
| Other inspected screens | Existing geometry retained where it matches or reflects an explicit user correction. No unrelated layout redesign. |

User-added appearance selector is in Settings. System/light/dark applies only to the login screen, as explicitly confirmed. Save preference in native application-support storage or web localStorage and load before first render; default/fallback is system. This is not app-wide dark mode. No new package dependency.

## Nickname feedback scope correction — 2026-11-20

The user clarified that only the success helper should move upward and the error feedback should match the design. Keep the nickname label/input and the counter below the underline. Both success and error helpers now share a single row with that counter, 8px below the input, rather than giving success a second row. Error feedback uses a red status icon and gray text; validation and 2–20 rule unchanged. This supersedes the previous above-line counter change.

## Main integration — 2026-11-20

Merged the UI branch onto main 0f51140 while preserving server collection lookup, acquisition dates, local photo/memo association, person selection and crop-coordinate handling. Existing high-resolution character assets remain canonical; MikuIllustration maps capture artwork to miku-cheer.png. User-approved maximum artwork sizing, header alignment, nickname 2–20 validation/feedback, all-consent and login-only appearance settings remain in place. Existing Pages production API configuration is retained; no mock authentication is enabled in production.
