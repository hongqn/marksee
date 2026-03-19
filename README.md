# MarkSee

A lightweight macOS Markdown viewer that renders `.md` files with GitHub Flavored Markdown styling, powered by [Textual](https://github.com/gonzalezreal/textual).

## Features

- GitHub Flavored Markdown rendering (headings, lists, tables, code blocks, blockquotes, etc.)
- Native macOS document-based app with file association and drag-and-drop support
- Syntax highlighting for code blocks
- Native text selection and copy-paste
- **Edit button** — opens the current file in any editor detected on your system; remembers your last choice
- **Default app integration** — prompts once after first use; can be set anytime via Help menu

## Requirements

- macOS 15+
- Swift 6.0 / Xcode 16+

## Build & Install

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

## Usage

- **Open a file**: File → Open (`Cmd+O`), or drag and drop a `.md` / `.markdown` file onto the app icon
- **Edit**: Click the Edit button in the toolbar to open the file in an external editor. If multiple editors are available, a menu appears; your choice is remembered for next time.
- **Set as default viewer**: On first file open, MarkSee asks if you'd like to be set as the default. You can also do this anytime via **Help → Set MarkSee as Default Markdown Viewer**.

## Tech Stack

- SwiftUI `DocumentGroup` — document-based app architecture
- [Textual](https://github.com/gonzalezreal/textual) — Markdown rendering
- `NSWorkspace` — editor discovery and default app registration

## License

MIT
