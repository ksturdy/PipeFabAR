#!/bin/bash
# Archive and Upload Script for PipeFabAR
# Version 1.1 (Build 2)

set -e  # Exit on error

echo "🚀 Starting archive and upload process..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_NAME="PipeFabAR"
SCHEME="PipeFabAR"
WORKSPACE_OR_PROJECT="-project ${PROJECT_NAME}.xcodeproj"
ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./build/export"

echo "${BLUE}Step 1/5: Cleaning previous builds...${NC}"
rm -rf build
mkdir -p build

echo ""
echo "${BLUE}Step 2/5: Building archive...${NC}"
xcodebuild archive \
    ${WORKSPACE_OR_PROJECT} \
    -scheme "${SCHEME}" \
    -archivePath "${ARCHIVE_PATH}" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=JVQ9659L8L \
    | xcpretty || echo "Note: xcpretty not installed (brew install xcpretty for prettier output)"

if [ ! -d "${ARCHIVE_PATH}" ]; then
    echo "${RED}❌ Archive failed!${NC}"
    exit 1
fi

echo ""
echo "${GREEN}✅ Archive created successfully${NC}"

echo ""
echo "${BLUE}Step 3/5: Validating archive...${NC}"
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates

if [ $? -ne 0 ]; then
    echo "${RED}❌ Export/validation failed!${NC}"
    exit 1
fi

echo ""
echo "${GREEN}✅ Archive validated and exported${NC}"

echo ""
echo "${BLUE}Step 4/5: Checking exported IPA...${NC}"
IPA_PATH="${EXPORT_PATH}/${PROJECT_NAME}.ipa"
if [ -f "${IPA_PATH}" ]; then
    IPA_SIZE=$(du -h "${IPA_PATH}" | cut -f1)
    echo "${GREEN}✅ IPA created: ${IPA_SIZE}${NC}"
    echo "   Location: ${IPA_PATH}"
else
    echo "${RED}❌ IPA not found!${NC}"
    exit 1
fi

echo ""
echo "${BLUE}Step 5/5: Upload options${NC}"
echo ""
echo "Your app is ready to upload to App Store Connect!"
echo ""
echo "Option 1 - Manual upload via Xcode:"
echo "  1. Open Xcode"
echo "  2. Window → Organizer"
echo "  3. Select the archive and click 'Distribute App'"
echo ""
echo "Option 2 - Command line upload (requires App Store Connect API key):"
echo "  xcrun altool --upload-app --type ios --file \"${IPA_PATH}\" \\"
echo "    --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER"
echo ""
echo "Option 3 - Use Transporter app:"
echo "  1. Open Transporter (from Mac App Store)"
echo "  2. Sign in with your Apple ID"
echo "  3. Drag and drop: ${IPA_PATH}"
echo ""
echo "${GREEN}🎉 Build process complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Upload to App Store Connect (use one of the options above)"
echo "  2. Log in to https://appstoreconnect.apple.com"
echo "  3. Add release notes (see RELEASE_NOTES.txt)"
echo "  4. Submit for review"
