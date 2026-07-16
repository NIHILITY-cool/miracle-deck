DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

.PHONY: generate build test verify clean

generate:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodegen generate

build: generate
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild \
		-project TokenMonitor.xcodeproj \
		-scheme TokenMonitor \
		-configuration Debug \
		-derivedDataPath DerivedData \
		CODE_SIGNING_ALLOWED=NO \
		build

test:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" swift test --package-path Packages/TokenMonitorCore
	DEVELOPER_DIR="$(DEVELOPER_DIR)" swift test --package-path Packages/TokenMonitorProviders
	DEVELOPER_DIR="$(DEVELOPER_DIR)" swift test --package-path Packages/TokenMonitorUI

verify: build test

clean:
	DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild \
		-project TokenMonitor.xcodeproj \
		-scheme TokenMonitor \
		-derivedDataPath DerivedData \
		clean
