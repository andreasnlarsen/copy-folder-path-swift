# Recon

Status: complete
Date: 2026-07-08

## Repo State

- Greenfield repo initialized on `main`.
- Existing project files before implementation:
  - `README.md`
  - `SPEC.md`
  - `docs/research.md`
- No existing source files, tests, build scripts, or progress files.

## Local Tooling

- Swift is available: Apple Swift 6.3.3.
- Full Xcode is not selected; `xcodebuild` requires Xcode and reports Command Line Tools only.
- Escalated compile probes confirmed AppKit, Carbon, and ServiceManagement import successfully outside the Codex sandbox.
- Codex sandbox can block Swift module cache writes under `~/.cache`, so SwiftPM commands may need escalated execution in this session.

## Build/Test Commands To Establish

- `swift run CopyFolderPathTests`
- `Scripts/build-app.sh`
- `Scripts/package-app.sh`

## Codebase Health

Greenfield. No files over 500 LoC except the single executable test harness, no large production functions, no duplicated business rules, no split authority.
