#!/bin/zsh

echo "iOS & macOS build script"
echo "Syntax: ./build.sh <config?>"
echo "Valid configurations: debug & release (Default: release)"

BINARY_PATH_IOS="dist/addons/apple_sign_in/ios"
BINARY_PATH_MACOS="dist/addons/apple_sign_in/macos"
BUILD_PATH_IOS=".build/arm64-apple-ios"
BUILD_PATH_MACOS=".build/x86_64-apple-macosx"

CONFIG=${1:-release}
COPY_COMMANDS=()

BOLD="$(tput bold)"
GREEN="$(tput setaf 2)"
CYAN="$(tput setaf 6)"
RED="$(tput setaf 1)"
RESET="$(tput sgr0)"

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
        echo "${BOLD}${RED}Failed to build iOS library${RESET}"
        return 1
    fi

    echo "${BOLD}${GREEN}iOS build succeeded${RESET}"

    product_path="$BUILD_PATH_IOS/Build/Products/$1-iphoneos/PackageFrameworks"
    for source in Sources/*; do
        COPY_COMMANDS+=("cp -af \"$product_path/$source:t:r.framework\" \"$BINARY_PATH_IOS\"")
    done
    COPY_COMMANDS+=("cp -af \"$product_path/SwiftGodot.framework\" \"$BINARY_PATH_IOS\"")
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
        echo "${BOLD}${RED}Failed to build macOS library${RESET}"
        return 1
    fi

    echo "${BOLD}${GREEN}macOS build succeeded${RESET}"

    product_path="$BUILD_PATH_MACOS/Build/Products/$1-macos/PackageFrameworks"
    [[ ! -d "$product_path" ]] && product_path="$BUILD_PATH_MACOS/Build/Products/$1/PackageFrameworks"

    for source in Sources/*; do
        COPY_COMMANDS+=("cp -af \"$product_path/$source:t:r.framework\" \"$BINARY_PATH_MACOS\"")
    done
    COPY_COMMANDS+=("cp -af \"$product_path/SwiftGodot.framework\" \"$BINARY_PATH_MACOS\"")
}

patch_swiftgodot_path() {
    local bin="$1"
    install_name_tool -change "@rpath/SwiftGodot.framework/Versions/A/SwiftGodot" "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot" "$bin" 2>/dev/null || true
    install_name_tool -change "@loader_path/../SwiftGodot.framework/Versions/A/SwiftGodot" "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot" "$bin" 2>/dev/null || true
    install_name_tool -change "@loader_path/../../SwiftGodot.framework/Versions/A/SwiftGodot" "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot" "$bin" 2>/dev/null || true
}

patch_frameworks() {
    local dir="$1"
    [[ ! -d "$dir" ]] && return
    echo "Patching macOS frameworks in $dir..."
    for fw in "$dir"/*.framework; do
        [[ ! -d "$fw" ]] && continue
        [[ "$(basename "$fw")" = "SwiftGodot.framework" ]] && continue
        local bin="$fw/$(basename "$fw" .framework)"
        [[ -f "$bin" ]] && patch_swiftgodot_path "$bin"
    done
}

verify_frameworks() {
    local dir="$1"
    [[ ! -d "$dir" ]] && return
    echo "Verifying macOS binaries in $dir..."
    for fw in "$dir"/*.framework; do
        [[ ! -d "$fw" ]] && continue
        [[ "$(basename "$fw")" = "SwiftGodot.framework" ]] && continue
        local bin="$fw/$(basename "$fw" .framework)"
        if [[ -f "$bin" ]] && otool -L "$bin" | grep -q "SwiftGodot.framework"; then
            if ! otool -L "$bin" | grep -q "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot"; then
                echo "ERROR: $bin has incorrect SwiftGodot path"
                exit 1
            fi
        fi
    done
}

build_libs() {
    echo "${BOLD}${CYAN}Building libraries ($1)...${RESET}"
    
    build_ios "$1"
    build_macos "$1"
    
    if [[ ${#COPY_COMMANDS[@]} -gt 0 ]]; then
        echo "${BOLD}${CYAN}Copying frameworks to dist/...${RESET}"
        rm -rf "$BINARY_PATH_IOS" "$BINARY_PATH_MACOS"
        mkdir -p "$BINARY_PATH_IOS" "$BINARY_PATH_MACOS"
        for instruction in ${COPY_COMMANDS[@]}; do
            eval $instruction
        done
        
        patch_frameworks "$BINARY_PATH_MACOS"

        if [[ -d "dist/addons" && -d "demo" ]]; then
            echo "Copying to demo/addons..."
            mkdir -p "demo/addons"
            rm -rf "demo/addons/apple_sign_in"
            cp -a dist/addons/* "demo/addons/"
            patch_frameworks "demo/addons/apple_sign_in/macos"
            verify_frameworks "demo/addons/apple_sign_in/macos"
        fi
    fi

    echo "${BOLD}${GREEN}Finished building $1 libraries${RESET}"
}

build_libs "$CONFIG"
