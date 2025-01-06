#!/bin/sh

xcodebuild archive -workspace OneDriveSDK.xcworkspace -scheme "OneDriveSDK" -destination "generic/platform=iOS" -archivePath "archives/OneDrive_iOS" SKIP_INSTALL=NO IPHONEOS_DEPLOYMENT_TARGET=12.1

xcodebuild archive -workspace OneDriveSDK.xcworkspace -scheme "OneDriveSDK" -destination "generic/platform=iOS Simulator" -archivePath "archives/OneDrive_iOS_Simulator" SKIP_INSTALL=NO IPHONEOS_DEPLOYMENT_TARGET=12.1

xcodebuild archive -workspace OneDriveSDK.xcworkspace -scheme "OneDriveSDK" -destination "generic/platform=macOS" -archivePath "archives/OneDrive_macOS" SKIP_INSTALL=NO IPHONEOS_DEPLOYMENT_TARGET=12.1

xcodebuild -create-xcframework -archive archives/OneDrive_iOS.xcarchive -framework OneDriveSDK.framework -archive archives/OneDrive_iOS_Simulator.xcarchive -framework OneDriveSDK.framework -archive archives/OneDrive_macOS.xcarchive -framework OneDriveSDK.framework -output xcframeworks/OneDriveSDK.xcframework
