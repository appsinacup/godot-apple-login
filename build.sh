#!/bin/zsh

# MARK: Help
echo "iOS & macOS build script"
echo "Syntax: ./build.sh <config?>"
echo "Valid configurations: debug & release (Default: release)"

# MARK: Settings
# Output into the distribution folder
BINARY_PATH_IOS="dist/addons/apple_sign_in/ios"
BINARY_PATH_MACOS="dist/addons/apple_sign_in/macos"
BUILD_PATH_IOS=".build/arm64-apple-ios"
BUILD_PATH_MACOS=".build/x86_64-apple-macosx"

# MARK: Inputs
CONFIG=$1
if [[ ! $CONFIG ]]; then
    CONFIG="release"
fi

COPY_COMMANDS=()

# MARK: Build iOS
build_ios() {
    xcodebuild \
        -scheme "AppleSignInLibrary" \
        -destination 'generic/platform=iOS' \
        -derivedDataPath "$BUILD_PATH_IOS" \
        -clonedSourcePackagesDirPath ".build" \
        -configuration "$1" \
        -skipPackagePluginValidation \
        -skipMacroValidation \
        -quiet

    if [[ $? -gt 0 ]]; then
        echo "${BOLD}${RED}Failed to build iOS library${RESET_FORMATTING}"
        return 1
    fi

    echo "${BOLD}${GREEN}iOS build succeeded${RESET_FORMATTING}"

    product_path="$BUILD_PATH_IOS/Build/Products/$1-iphoneos/PackageFrameworks"
    source_path="Sources"
    for source in $source_path/*; do
        COPY_COMMANDS+=("cp -af \"$product_path/$source:t:r.framework\" \"$BINARY_PATH_IOS\"")
    done

    COPY_COMMANDS+=("cp -af \"$product_path/SwiftGodot.framework\" \"$BINARY_PATH_IOS\"")

    return 0
}

build_macos() {
    xcodebuild \
        -scheme "AppleSignInLibrary" \
        -destination 'generic/platform=macOS' \
        -derivedDataPath "$BUILD_PATH_MACOS" \
        -clonedSourcePackagesDirPath ".build" \
        -configuration "$1" \
        -skipPackagePluginValidation \
        -skipMacroValidation \
        -quiet

    if [[ $? -gt 0 ]]; then
        echo "${BOLD}${RED}Failed to build macOS library${RESET_FORMATTING}"
        return 1
    fi

    echo "${BOLD}${GREEN}macOS build succeeded${RESET_FORMATTING}"

    # Try both possible product locations we might find depending on Xcode/SPM layout
    product_path="$BUILD_PATH_MACOS/Build/Products/$1-macos/PackageFrameworks"
    if [[ ! -d "$product_path" ]]; then
        product_path="$BUILD_PATH_MACOS/Build/Products/$1/PackageFrameworks"
    fi

    source_path="Sources"
    for source in $source_path/*; do
        COPY_COMMANDS+=("cp -af \"$product_path/$source:t:r.framework\" \"$BINARY_PATH_MACOS\"")
    done

    COPY_COMMANDS+=("cp -af \"$product_path/SwiftGodot.framework\" \"$BINARY_PATH_MACOS\"")

    return 0
}

# MARK: Pre & Post process
build_libs() {
    echo "${BOLD}${CYAN}Building iOS libraries ($1)...${RESET_FORMATTING}"
    
    build_ios "$1"
    build_macos "$1"
    
    if [[ ${#COPY_COMMANDS[@]} -gt 0 ]]; then
        echo "${BOLD}${CYAN}Copying frameworks into dist/addons/apple_sign_in...${RESET_FORMATTING}"
        for instruction in ${COPY_COMMANDS[@]}
        do
            # target is the last token; create parent dir and then run the copy
            target=${instruction##* }
            parent=$(dirname "$target")
            mkdir -p "$parent"
            eval $instruction
        done
    fi

    echo "${BOLD}${GREEN}Finished building $1 libraries for iOS and macOS${RESET_FORMATTING}"
}

# MARK: Formatting
BOLD="$(tput bold)"
GREEN="$(tput setaf 2)"
CYAN="$(tput setaf 6)"
RED="$(tput setaf 1)"
RESET_FORMATTING="$(tput sgr0)"

# MARK: Run
build_libs "$CONFIG"
