# Changelog

All notable changes to this project will be documented in this file.

The project follows semantic versioning after the first public release.

## [Unreleased]

### Changed

- Renamed the product, Xcode project, Swift packages, and identifiers from the
  temporary Token Monitor name to MiracleDeck.
- Adopted `cool.nihility.miracledeck` as the application bundle identifier.
- Reduced the menu panel height and tightened card and provider-row spacing.
- Reworked the prototype palette around a cool neutral surface, restrained
  status accents, and a soft Aurora hero inspired by Quota Float.
- Subscription cards now show exact quota reset dates and times, plus a compact
  weekly remaining quota summary without increasing the panel size.
- Refined subscription quota hierarchy with a separate "本周" badge, date-only
  weekly reset information, animated account selection and quota transitions.
- Added a short menu-panel entrance animation and status-aware ambient color
  bleed around the hero card while keeping the panel background stable.
- Removed the weekly quota container and paired its label with the reset date.
- Strengthened the status-aware ambient wash around the hero so its changing
  card color blends into the stable panel background instead of ending abruptly.
- Made the bright pearl glass surface the default and increased its lightness.
- Limited the provider list viewport to three rows while allowing vertical
  scrolling for additional accounts.
- Added drag-to-reorder behavior for provider rows.
- Added an internal card mode that expands the selected hero across the panel,
  supports horizontal or vertical account swipes, and collapses on double-click.
- Expanded card mode into a provider-specific information layout with the
  primary metric, reset details, weekly quota, data source, and update time.
- Tuned card swipes to require a deliberate gesture, ignore trackpad momentum,
  and switch at most one account per gesture.
- Replaced the shared-geometry mode swap with one persistent Hero surface that
  resizes in place; account identity, the primary metric, and quota progress now
  move continuously between layouts, while mode-specific details fade in after
  the surface begins moving.
- Restored reliable card-mode exit with a native double-click recognizer and an
  Escape-key fallback, and stopped progress rails replaying their zero-to-value
  decoration during mode changes.
- Removed low-value data-source fields from card content, keeping only update
  time where metadata is useful; shared mode content now combines geometry
  movement with a short opacity crossfade instead of appearing immediately.
- Synchronized all mode-content fades with the Hero surface's 0.42-second
  expansion and contraction timeline, removing independent delays and speeds.
- Reduced the panel footprint by roughly 20 percent to 294 × 320 points while
  preserving primary and weekly metric type sizes; tightened non-core spacing,
  controls, and provider rows so three accounts remain visible.
- Replaced shared-content handoff with one persistent identity, primary metric,
  and quota-progress layer whose position and scale animate continuously between
  arrangement and card modes.
- Rebalanced card mode around Quota Float's header, primary metric, progress,
  and anchored secondary-metric composition.
- Reduced percentage-symbol prominence, opened up balance typography, and added
  recent seven-day spend for balance-based accounts.
- Added card-mode refresh and settings controls and replaced letter tiles with
  transparent monochrome Codex, DeepSeek, and New API provider marks.
- Filled the expanded card's unused center with a borderless data ledger:
  quota accounts show consumed quota, reset countdown, and source; balance
  accounts show requests, token volume, and average request cost.
- Removed the misleading recent-spend-to-balance progress rail. Balance cards
  now use a clear three-part hierarchy: available balance, usage ledger, then
  recent spend.
- Removed weekly quota from the compact arrangement Hero, where it competed
  with the primary quota. Weekly remaining quota stays in expanded card mode.
- Re-anchored compact update time, provider mark, and status dot; increased
  arrangement-row metric type to 12 points with semibold weight.
- Simplified expanded quota cards by removing the consumed-cycle ledger. The
  recovery countdown now sits directly below the exact reset time, while the
  weekly secondary metric includes an optional provider-reported reset count.
- Bottom-aligned the expanded secondary-metric region to the provider mark, so
  quota and balance variants share one lower boundary and extra rows grow
  upward instead of extending beyond the composition.
- Split expanded quota and balance primary-metric coordinates. Their different
  type scales now align on a shared visual lower edge and remain independently
  adjustable in the layout workbench.
- Enlarged secondary spend and weekly metrics, placed currency codes after
  monetary values, and reduced provider-logo size in arrangement rows.

### Added

- Added a Debug-only layout workbench behind the settings buttons. It renders
  the real arrangement or card surface, supports direct dragging of identity,
  primary metric, progress, status, update time, provider mark, insight row,
  and secondary metric regions, plus precise coordinates, component sizes,
  account previews, one-point nudging, reset, JSON export, and persistent apply.
- Extracted panel geometry into a validated `DeckLayoutPreset`; saved layouts
  are restored across launches and the native status-bar panel adopts edited
  dimensions the next time it opens.
- Native macOS menu bar application skeleton using `NSStatusItem + NSPanel`.
- Mock DeepSeek, Codex, and New API provider snapshots.
- Local Swift packages for domain, providers, and UI.
- Swift 6 strict-concurrency configuration.
- macOS 14 deployment target.
- Basic package tests and GitHub Actions workflow.
- Privacy, security, contribution, design, research, and implementation docs.
- A documented five-theme glass palette for the future settings system.
- Split the arrangement-mode primary metric into independent quota and balance
  coordinates. Their different type scales now share a visual lower edge, and
  the layout workbench edits each account type independently.
- Reworked the arrangement-to-card color transition as one absolute-coordinate
  gradient field calibrated to the original compact hero. Its centers and
  transition distances never move or crossfade; the expanding card simply
  reveals the field's continuation beyond the original compact bounds.
- Restored full-surface double-click hit testing after separating the hero
  gradient from its content layer.
