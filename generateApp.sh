#!/bin/zsh

# Function to display usage
usage() {
    echo "Usage: $0 <URL> <App Name>"
    exit 1
}

# Function to create app directory structure
create_app_structure() {
    local app_name="$1"
    local app_dir="${app_name}.app"
    local contents_dir="${app_dir}/Contents"
    local macos_dir="${contents_dir}/MacOS"
    local resources_dir="${contents_dir}/Resources"

    mkdir -p "${macos_dir}" "${resources_dir}"
    echo "${contents_dir}"
}

# Function to create Info.plist
create_info_plist() {
    local contents_dir="$1"
    local app_name="$2"

    cat > "${contents_dir}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${app_name}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.${app_name}</string>
    <key>CFBundleName</key>
    <string>${app_name}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF
}

# Function to create executable script
create_executable() {
    local macos_dir="$1"
    local app_name="$2"
    local url="$3"

    cat > "${macos_dir}/${app_name}" << EOF
#!/bin/zsh
/usr/bin/open -a "Safari" -n "${url}"
EOF

    chmod +x "${macos_dir}/${app_name}"
}

# Function to set library path and run convert
run_convert() {
    local convert_tool="$1"
    shift
    export DYLD_LIBRARY_PATH="./external/lib:$DYLD_LIBRARY_PATH"
    "${convert_tool}" "$@"
}

# Function to download icon
download_icon() {
    local url="$1"
    local resources_dir="$2"

    # Array of possible icon sources
    local icon_sources=(
        "apple-touch-icon"
        "favicon"
        "og:image"
        "google-favicon"
    )

    for source in "${icon_sources[@]}"; do
        local icon_url=""
        local icon_ext="png"

        case "$source" in
            "apple-touch-icon")
                icon_url=$(curl -s "${url}" | grep -o '<link rel="apple-touch-icon" href="[^"]*"' | sed 's/.*href="\([^"]*\)".*/\1/' | head -n 1)
                ;;
            "favicon")
                icon_url=$(curl -s "${url}" | grep -o '<link rel="icon" href="[^"]*"' | sed 's/.*href="\([^"]*\)".*/\1/' | head -n 1)
                ;;
            "og:image")
                icon_url=$(curl -s "${url}" | grep -o '<meta property="og:image" content="[^"]*"' | sed 's/.*content="\([^"]*\)".*/\1/' | head -n 1)
                ;;
            "google-favicon")
                icon_url="https://www.google.com/s2/favicons?sz=256&domain_url=${url}"
                ;;
        esac

        if [[ -n "${icon_url}" ]]; then
            if [[ "${icon_url}" != http* ]]; then
                icon_url="${url%/}/${icon_url#/}"
            fi

            echo "Attempting to download icon from: ${icon_url}"
            if curl -L -o "${resources_dir}/icon_temp" "${icon_url}"; then
                if [[ ! -s "${resources_dir}/icon_temp" ]]; then
                    echo "Downloaded file is empty. Trying next source."
                    rm "${resources_dir}/icon_temp"
                    continue
                fi

                # Determine file type and convert to PNG if necessary
                local file_type=$(file -b --mime-type "${resources_dir}/icon_temp")
                case "$file_type" in
                    "image/png")
                        mv "${resources_dir}/icon_temp" "${resources_dir}/icon.png"
                        ;;
                    "image/jpeg")
                        local convert_tool=$(download_imagemagick "external")
                        run_convert "${convert_tool}" "${resources_dir}/icon_temp" "${resources_dir}/icon.png"
                        rm "${resources_dir}/icon_temp"
                        ;;
                    "image/x-icon" | "image/vnd.microsoft.icon")
                        local convert_tool=$(download_imagemagick "external")
                        run_convert "${convert_tool}" "${resources_dir}/icon_temp" "${resources_dir}/icon.png"
                        rm "${resources_dir}/icon_temp"
                        ;;
                    *)
                        echo "Unsupported file type: $file_type. Trying next source."
                        rm "${resources_dir}/icon_temp"
                        continue
                        ;;
                esac

                if [[ -f "${resources_dir}/icon.png" ]]; then
                    echo "Successfully downloaded and converted icon from $source"
                    return 0
                else
                    echo "Failed to create icon.png. Trying next source."
                fi
            else
                echo "Failed to download icon from $source. Trying next source."
            fi
        fi
    done

    echo "Failed to download icon from any source"
    return 1
}

# Function to convert ICO to PNG
convert_ico_to_png() {
    local resources_dir="$1"
    local convert_tool="$2"

    run_convert "${convert_tool}" "${resources_dir}/icon.ico" "${resources_dir}/icon.png"
    rm "${resources_dir}/icon.ico"
    echo "Successfully converted ICO to PNG."
}

# Function to download ImageMagick
download_imagemagick() {
    local tools_dir="$1"
    mkdir -p "${tools_dir}"

    # Check if ImageMagick.tar.gz already exists
    if [[ -f "${tools_dir}/ImageMagick.tar.gz" ]]; then
        # printf "Found existing ImageMagick.tar.gz, attempting to use it...\n"
        if tar -tzf "${tools_dir}/ImageMagick.tar.gz" &> /dev/null; then
            # printf "Existing ImageMagick.tar.gz is valid, extracting...\n"
            tar -xzf "${tools_dir}/ImageMagick.tar.gz" -C "${tools_dir}" --strip-components=1
            
            # Handle potential symlinks
            if [[ -L "${tools_dir}/bin/convert" ]]; then
                cp -RH "${tools_dir}/bin/convert" "${tools_dir}/bin/convert_real"
                mv "${tools_dir}/bin/convert_real" "${tools_dir}/bin/convert"
            fi
            
            echo "${tools_dir}/bin/convert"
            return 0
        # else
            # printf "Existing ImageMagick.tar.gz is not valid, will attempt to download...\n"
        fi
    fi

    local imagemagick_sources=(
        "https://download.imagemagick.org/ImageMagick/download/binaries/ImageMagick-x86_64-apple-darwin20.1.0.tar.gz"
        "https://github.com/ImageMagick/ImageMagick/releases/download/7.1.1-15/ImageMagick-x86_64-apple-darwin20.1.0.tar.gz"
    )

    for source in "${imagemagick_sources[@]}"; do
        if curl -L "$source" -o "${tools_dir}/ImageMagick.tar.gz"; then
            if tar -tzf "${tools_dir}/ImageMagick.tar.gz" &> /dev/null; then
                # printf "Successfully downloaded ImageMagick from %s\n" "$source"
                tar -xzf "${tools_dir}/ImageMagick.tar.gz" -C "${tools_dir}" --strip-components=1
                
                # Handle potential symlinks
                if [[ -L "${tools_dir}/bin/convert" ]]; then
                    cp -RH "${tools_dir}/bin/convert" "${tools_dir}/bin/convert_real"
                    mv "${tools_dir}/bin/convert_real" "${tools_dir}/bin/convert"
                fi
                
                #rm "${tools_dir}/ImageMagick.tar.gz"
                echo "${tools_dir}/bin/convert"
                return 0
            else
                # printf "Downloaded file is not a valid tar.gz archive. Trying next source...\n"
                rm "${tools_dir}/ImageMagick.tar.gz"
            fi
        # else
            # printf "Failed to download from %s. Trying next source...\n" "$source"
        fi
    done

    echo ""
    return 1
}

# Function to convert PNG to ICNS
convert_to_icns() {
    local input="$1"
    local output="$2"
    local tool="$3"

    case "$tool" in
        "sips")
            sips -s format icns "$input" --out "$output"
            ;;
        "convert")
            local convert_tool=$(download_imagemagick "external")
            run_convert "${convert_tool}" "$input" "$output"
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to convert icon to ICNS
convert_icon_to_icns() {
    local resources_dir="$1"
    local icon_ext="$2"

    # Ensure convert tool is available
    local convert_tool=$(download_imagemagick "external")
    if [[ -z "$convert_tool" ]]; then
        echo "Error: Failed to download 'convert' tool. Cannot convert icon."
        return 1
    fi

    # Convert ICO to PNG if necessary
    if [[ "${icon_ext}" = "ico" ]]; then
        convert_ico_to_png "$resources_dir" "$convert_tool"
    fi

    # Convert PNG to ICNS
    if [[ -x "$convert_tool" ]]; then
        if run_convert "$convert_tool" "${resources_dir}/icon.png" "${resources_dir}/AppIcon.icns"; then
            echo "Successfully converted icon using convert tool."
            rm "${resources_dir}/icon.png"
            return 0
        else
            echo "Failed to convert icon using convert tool. Error code: $?"
        fi
    else
        echo "Error: Convert tool not found or not executable at $convert_tool"
    fi

    # If all conversion attempts fail, use PNG as icon
    echo "Warning: Could not convert PNG to ICNS. Using PNG file as icon."
    cp "${resources_dir}/icon.png" "${resources_dir}/AppIcon.icns"
    return 0
}

# Main script execution
main() {
    # Check if required arguments are provided
    if [[ $# -ne 2 ]]; then
        usage
    fi

    local url="$1"
    local app_name="$2"

    # Create app structure
    local contents_dir=$(create_app_structure "$app_name")
    local macos_dir="${contents_dir}/MacOS"
    local resources_dir="${contents_dir}/Resources"

    # Create Info.plist
    create_info_plist "$contents_dir" "$app_name"

    # Create executable script
    create_executable "$macos_dir" "$app_name" "$url"

    # Download icon
    local icon_ext=$(download_icon "$url" "$resources_dir")

    # Convert icon to ICNS
    if ! convert_icon_to_icns "$resources_dir" "$icon_ext"; then
        echo "Error: Failed to convert icon."
        exit 1
    fi

    echo "App '${app_name}' created successfully."

    # Ask user if they want to move the app to the Applications folder
    read "move_to_applications?Do you want to move '${app_name}.app' to the Applications folder? (y/n): "
    if [[ $move_to_applications =~ ^[Yy]$ ]]; then
        mv "${app_name}.app" "/Applications/"
        echo "App moved to Applications folder."
    fi

    # Ask user if they want to add the app to the Dock
    read "add_to_dock?Do you want to add '${app_name}.app' to the Dock? (y/n): "
    if [[ $add_to_dock =~ ^[Yy]$ ]]; then
        if [[ $move_to_applications =~ ^[Yy]$ ]]; then
            defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/${app_name}.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
        else
            defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$(pwd)/${app_name}.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
        fi
        killall Dock
        echo "App added to Dock."
    fi

    echo "App setup complete."
}

# Run the main function
main "$@"
