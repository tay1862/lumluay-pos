# iOS Bundle Identifier
# The bundle ID is set in Runner.xcodeproj / project.pbxproj
# and in Info.plist as $(PRODUCT_BUNDLE_IDENTIFIER).
#
# Production   : com.lumluay.pos
# Staging      : com.lumluay.pos.staging
# Dev          : com.lumluay.pos.dev
#
# Provisioning profiles must be configured in Xcode:
#   Xcode → Runner target → Signing & Capabilities
#   → Select correct Team & Provisioning Profile per scheme.
#
# For CI (Fastlane / GitHub Actions):
#   Use `fastlane match` or upload .p12 + .mobileprovision
#   and set APPLE_TEAM_ID, PROVISIONING_PROFILE env vars.
