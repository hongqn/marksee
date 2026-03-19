APP_NAME   = MarkSee
BUILD_DIR  = .build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
BINARY     = $(BUILD_DIR)/release/$(APP_NAME)
PLIST_SRC  = Sources/MarkSee/Info.plist
ICON_SRC   = Sources/MarkSee/AppIcon.icns

.PHONY: build run dev clean dmg

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

## Build a distributable DMG
## Usage: make dmg VERSION=1.0.0
dmg: build
	@test -n "$(VERSION)" || (echo "Error: VERSION is required. Usage: make dmg VERSION=1.0.0" && false)
	rm -rf "/tmp/$(APP_NAME)-dmg-staging"
	mkdir -p "/tmp/$(APP_NAME)-dmg-staging"
	cp -r $(APP_BUNDLE) "/tmp/$(APP_NAME)-dmg-staging/$(APP_NAME).app"
	ln -s /Applications "/tmp/$(APP_NAME)-dmg-staging/Applications"
	hdiutil create -volname $(APP_NAME) \
	  -srcfolder "/tmp/$(APP_NAME)-dmg-staging" \
	  -ov -format UDZO \
	  -o "$(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg"
	rm -rf "/tmp/$(APP_NAME)-dmg-staging"
	@echo "Created: $(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg"
	@shasum -a 256 "$(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg"

## Remove build artifacts
clean:
	rm -rf $(BUILD_DIR)
