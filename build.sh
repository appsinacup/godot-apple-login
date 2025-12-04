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
        rm -rf "$BINARY_PATH_IOS" "$BINARY_PATH_MACOS"
        mkdir -p "$BINARY_PATH_IOS" "$BINARY_PATH_MACOS"
        for instruction in ${COPY_COMMANDS[@]}
        do
            eval $instruction
        done
        
        # On macOS: ensure the extension looks up SwiftGodot relative to its location
        # so the runtime loader finds the dependency at res://addons/apple_sign_in/macos/SwiftGodot.framework
        if [[ -d "$BINARY_PATH_MACOS" ]]; then
            echo "Patching macOS frameworks to use @loader_path for SwiftGodot..."
            for fw in "$BINARY_PATH_MACOS"/*.framework; do
                if [[ -d "$fw" ]]; then
                    bin="$fw/$(basename "$fw" .framework)"
                    if [[ -f "$bin" ]]; then
                        echo "Patching $bin"
                        # The framework binary lives at:
                        # macos/AppleSignInLibrary.framework/Versions/A/AppleSignInLibrary
                        # SwiftGodot.framework is located at macos/SwiftGodot.framework -> to reach it
                        # we need to go two directories up from the binary's loader path.
                        # try to replace either @rpath or an earlier @loader_path/../ (safe idempotent)
                        # Point the extension to the SwiftGodot framework at dist/addons/apple_sign_in/macos/
                        # The binary lives at: macos/AppleSignInLibrary.framework/Versions/A/AppleSignInLibrary
                        # To reach macos/SwiftGodot.framework we must go up three levels from Versions/A -> ../../.. -> macos
                        install_name_tool -change "@rpath/SwiftGodot.framework/Versions/A/SwiftGodot" "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot" "$bin" || true
                        install_name_tool -change "@loader_path/../SwiftGodot.framework/Versions/A/SwiftGodot" "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot" "$bin" || true
                    fi
                fi
            done
        fi

        # If there is a local demo project, copy dist/addons into demo/addons so the demo stays up-to-date
        DEMO_ADDONS="demo/addons"
        if [[ -d "dist/addons" && -d "demo" ]]; then
            echo "Copying dist/addons into demo/addons (overwriting demo/addons/apple_sign_in)..."
            mkdir -p "$DEMO_ADDONS"
            # remove existing addon folder and copy the freshly built one
            rm -rf "$DEMO_ADDONS/apple_sign_in" || true
            cp -a dist/addons/* "$DEMO_ADDONS/"
            # After copying to demo, ensure demo binaries are patched too (same install_name_tool fix)
            if [[ -d "$DEMO_ADDONS/apple_sign_in/macos" ]]; then
                echo "Patching demo macOS frameworks to use @loader_path -> SwiftGodot"
                for fw in "$DEMO_ADDONS/apple_sign_in/macos"/*.framework; do
                    if [[ -d "$fw" ]]; then
                        bin="$fw/$(basename "$fw" .framework)"
                        if [[ -f "$bin" ]]; then
                            install_name_tool -change "@rpath/SwiftGodot.framework/Versions/A/SwiftGodot" "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot" "$bin" || true
                            install_name_tool -change "@loader_path/../SwiftGodot.framework/Versions/A/SwiftGodot" "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot" "$bin" || true
                            install_name_tool -change "@loader_path/../../SwiftGodot.framework/Versions/A/SwiftGodot" "@loader_path/../../../SwiftGodot.framework/Versions/A/SwiftGodot" "$bin" || true
                        fi
                    fi
                done
            fi
            echo "Demo addons updated: $DEMO_ADDONS"
        fi
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
