xcodebuild archive \
  -scheme LoopKit \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath ./build/LoopKit-iOS.xcarchive \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild archive \
  -scheme LoopKit \
  -configuration Release \
  -destination "generic/platform=iOS Simulator" \
  -archivePath ./build/LoopKit-iOS-Simulator.xcarchive \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild archive \
  -scheme LoopKit \
  -configuration Release \
  -destination "generic/platform=watchOS" \
  -archivePath ./build/LoopKit-watchOS.xcarchive \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild archive \
  -scheme LoopKit \
  -configuration Release \
  -destination "generic/platform=watchOS Simulator" \
  -archivePath ./build/LoopKit-watchOS-Simulator.xcarchive \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES
xcodebuild -create-xcframework \
  -framework ./build/LoopKit-iOS.xcarchive/Products/Library/Frameworks/LoopKit.framework \
  -framework ./build/LoopKit-iOS-Simulator.xcarchive/Products/Library/Frameworks/LoopKit.framework \
  -framework ./build/LoopKit-watchOS.xcarchive/Products/Library/Frameworks/LoopKit.framework \
  -framework ./build/LoopKit-watchOS-Simulator.xcarchive/Products/Library/Frameworks/LoopKit.framework \
  -output ./LoopKit.xcframework
