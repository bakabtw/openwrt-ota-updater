#!/bin/sh

current_version=1.0
update_server_url="http://localhost:8000/check_updates"

check_for_updates() {
    local current_version=$1
    local update_server_url=$2

    response=$(wget -q -O - "$update_server_url")
    latest_version=$(echo "$response" | jq -r '.version')
    
    if [[ -n "$latest_version" && "$latest_version" > "$current_version" ]]; then
        update_available=true
        download_url=$(echo "$response" | jq -r '.download_url')
        expected_sha1=$(echo "$response" | jq -r '.sha1_hash')
    else
        update_available=false
        latest_version=$current_version
    fi
}

calculate_sha1() {
    local file_path=$1
    sha1sum "$file_path" | cut -d ' ' -f 1
}

check_sha1() {
    local file_path=$1
    local expected_sha1=$2

    actual_sha1=$(calculate_sha1 "$file_path")

    [[ "$actual_sha1" == "$expected_sha1" ]]
}

download_update() {
    local download_url=$1
    local destination_path=$2

    wget -q -O "$destination_path" "$download_url"
}

main() {
    check_for_updates "$current_version" "$update_server_url"

    if $update_available; then
        echo "Update available! Current version: $current_version, Latest version: $latest_version"
        download_folder="/tmp/"
        download_path="$download_folder/ota-firmware-update.bin"
        download_update "$download_url" "$download_path"

        # Checking SHA1 hash of downloaded firmware
        if check_sha1 "$download_path" "$expected_sha1"; then
            echo "Checking firmware integrity: OK"
        else
            echo "Checking firmware integrity: FAIL"
            echo "Expected SHA1: $expected_sha1"
            echo "Actual SHA1: $(calculate_sha1 "$download_path")"
            exit 1
        fi
    else
        echo "No updates available. Current version: $current_version"
    fi
}

# TODO: firmware sysupgrade
# TODO: installation
main
