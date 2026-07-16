DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

.PHONY: generate build test verify clean

generate:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodegen generate

build: generate
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild \
		-project MiracleDeck.xcodeproj \
		-scheme MiracleDeck \
		-configuration Debug \
		-derivedDataPath DerivedData \
		CODE_SIGNING_ALLOWED=NO \
		build

test:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" swift test --package-path Packages/MiracleDeckCore
	DEVELOPER_DIR="$(DEVELOPER_DIR)" swift test --package-path Packages/MiracleDeckProviders
	DEVELOPER_DIR="$(DEVELOPER_DIR)" swift test --package-path Packages/MiracleDeckUI

verify: build test

clean:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild \
		-project MiracleDeck.xcodeproj \
		-scheme MiracleDeck \
		-derivedDataPath DerivedData \
		clean
