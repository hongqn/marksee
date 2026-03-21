# MarkSee

<img src="icon.png" width="64" alt="MarkSee icon">

A lightweight macOS Markdown viewer that renders `.md` files with GitHub Flavored Markdown styling, powered by [Textual](https://github.com/gonzalezreal/textual).

## Features

- GitHub Flavored Markdown rendering (headings, lists, tables, code blocks, blockquotes, etc.)
- Native macOS document-based app with file association and drag-and-drop support
- Syntax highlighting for code blocks
- Native text selection and copy-paste
- **Find** (`Cmd+F`) — in-document search with match count and prev/next navigation
- **Table of Contents** — collapsible sidebar listing all headings; click to scroll
- **Print / Export PDF** (`Cmd+P`) — native macOS print panel with Save as PDF support
- **Theme switching** — System, GitHub Light, or GitHub Dark (via Settings)
- **Edit button** — opens the current file in any editor detected on your system; remembers your last choice
- **Default app integration** — prompts once after first use; can be set anytime via Settings

## Installation

```bash
brew tap hongqn/marksee
brew install --cask marksee
```

## Build from Source

### Requirements

- macOS 15+
- Swift 6.0 / Xcode 16+

### Build & Install

```bash
make build          # build release .app bundle
make run            # build and launch
make open FILE=path/to/file.md  # open a specific file
make clean          # remove build artifacts
```

To install to `/Applications`:

```bash
cp -r .build/MarkSee.app /Applications/
```

After installing, open any Markdown file from the command line:

```bash
open -a MarkSee path/to/file.md
```

### Release & Notarization

To build a signed, notarized DMG for distribution:

1. **Set up credentials** (one-time):
   ```bash
   xcrun notarytool store-credentials "marksee-notarize" \
     --apple-id YOUR_APPLE_ID \
     --team-id YOUR_TEAM_ID \
     --password APP_SPECIFIC_PASSWORD
   ```

2. **Build and notarize**:
   ```bash
   make notarize \
     VERSION=1.0.0 \
     SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
   ```

   This will:
   - Build a signed `.app` with Hardened Runtime enabled
   - Package it into a `.dmg`
   - Submit to Apple's notarization service and wait for approval
   - Staple the notarization ticket to the DMG

## Usage

- **Open a file**: File → Open (`Cmd+O`), or drag and drop a `.md` / `.markdown` file onto the app icon
- **Find**: Press `Cmd+F` to open the find bar. Type to search; `Enter`/`Shift+Enter` to navigate matches; `Esc` to close.
- **Table of Contents**: Click the list icon in the toolbar to toggle the heading sidebar.
- **Print / Export PDF**: `Cmd+P` opens the macOS print panel. Choose "Save as PDF" to export.
- **Theme**: Open Settings (`Cmd+,`) → Appearance to switch between System, GitHub Light, and GitHub Dark.
- **Edit**: Click the Edit button in the toolbar to open the file in an external editor.
- **Set as default viewer**: On first file open, MarkSee asks if you'd like to be set as the default. You can also do this anytime via **Settings → File Associations**.

## Tech Stack

- SwiftUI `DocumentGroup` — document-based app architecture
- [Textual](https://github.com/gonzalezreal/textual) — Markdown rendering
- `NSWorkspace` — editor discovery and default app registration
- `NSPrintOperation` — native print / export to PDF

## License

MIT
