# MarkSee

A lightweight macOS Markdown viewer that renders `.md` files with GitHub Flavored Markdown styling, powered by [Textual](https://github.com/gonzalezreal/textual).

## Features

- GitHub Flavored Markdown rendering (headings, lists, tables, code blocks, blockquotes, etc.)
- Native macOS document-based app with file association and drag-and-drop support
- Syntax highlighting for code blocks
- Native text selection and copy-paste

## Requirements

- macOS 15+
- Xcode 16+

## Build & Run

Open the project in Xcode:

```bash
open Package.swift
```

Select the `MarkSee` scheme and press `Cmd+R` to run.

Once running, open Markdown files via:

- **File → Open** (`Cmd+O`)
- Drag and drop a `.md` file onto the app icon in the Dock

## Tech Stack

- SwiftUI `DocumentGroup` — document-based app architecture
- [Textual](https://github.com/gonzalezreal/textual) — Markdown rendering

## License

MIT
