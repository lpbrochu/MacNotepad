# MacNotepad

MacNotepad is a tiny native macOS notepad app inspired by the simple Windows Notepad interface.

## Features

- Plain text editing with a single uncluttered window
- New, Open, Save, and Save As
- UTF-8 `.txt` file support
- Word Wrap toggle
- Status bar with line, column, character count, and path
- Find, Find Previous, Replace, and Replace All
- Font size controls
- Custom macOS app icon inspired by Windows Notepad

## Run

```sh
swift run MacNotepad
```

## Build

```sh
swift build
```

## Build a macOS app bundle

```sh
./scripts/build-app.sh
```

The generated app is written to `build/MacNotepad.app`.
