APP_NAME   = MarkSee
BUILD_DIR  = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
BINARY     = $(BUILD_DIR)/release/$(APP_NAME)
PLIST_SRC  = Sources/MarkSee/Info.plist
ICON_SRC   = Sources/MarkSee/AppIcon.icns

.PHONY: build run dev clean

## Build a release .app bundle
build:
	swift build -c release
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	cp $(BINARY) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	cp $(PLIST_SRC) $(APP_BUNDLE)/Contents/Info.plist
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(ICON_SRC) $(APP_BUNDLE)/Contents/Resources/AppIcon.icns

## Build and launch the app
run: build
	open $(APP_BUNDLE)

## Quick debug run without assembling a bundle (no file associations)
dev:
	swift run MarkSee

## Open a specific file in the built app
## Usage: make open FILE=path/to/file.md
open: build
	open -a $(APP_BUNDLE) $(FILE)

## Remove build artifacts
clean:
	rm -rf $(BUILD_DIR)
