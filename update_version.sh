#!/bin/bash
# Version Update Script for macOS/Linux
# Usage: ./update_version.sh <version_name> <build_number>
# Example: ./update_version.sh 1.0.1 2

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: ./update_version.sh <version_name> <build_number>"
    echo "Example: ./update_version.sh 1.0.1 2"
    exit 1
fi

VERSION_NAME=$1
BUILD_NUMBER=$2

echo "Updating version to ${VERSION_NAME}+${BUILD_NUMBER}..."

# Update pubspec.yaml
sed -i.bak "s/version: .*/version: ${VERSION_NAME}+${BUILD_NUMBER}/" pubspec.yaml
rm pubspec.yaml.bak

echo "✓ Version updated successfully!"
echo ""
echo "Next steps:"
echo "1. Commit the changes: git add pubspec.yaml"
echo "2. Create a tag: git tag v${VERSION_NAME}"
echo "3. Push: git push origin main --tags"
echo ""
