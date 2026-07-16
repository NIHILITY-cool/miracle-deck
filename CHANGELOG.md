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

### Added

- Native macOS menu bar application skeleton using `NSStatusItem + NSPanel`.
- Mock DeepSeek, Codex, and New API provider snapshots.
- Local Swift packages for domain, providers, and UI.
- Swift 6 strict-concurrency configuration.
- macOS 14 deployment target.
- Basic package tests and GitHub Actions workflow.
- Privacy, security, contribution, design, research, and implementation docs.
