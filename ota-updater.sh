#!/bin/bash

current_version=1
update_server_url="https://raw.githubusercontent.com/bakabtw/openwrt-ota-updater/main/server/check_updates"

check_for_updates() {
    local current_version=$1
    local update_server_url=$2

    updates_file="/tmp/check_updates.txt"

    wget -q -O "$updates_file" "$update_server_url" || rm -f $updates_file

    if [ -f "$updates_file" ]; then
        source "$updates_file"
        echo "INFO - Accessing the update server..."
    else
        echo "ERROR - Couldn't access the update server!"
        exit 1
    fi

    if ! [[ -n "$version" && -n "$download_url" && -n "$sha1_hash" ]]; then
        echo "ERROR - Incorrect response from the server: provided data is incorrect"
        exit 1
    else
        latest_version=$version
    fi
    
    if [[ "$latest_version" > "$current_version" ]]; then
        update_available=true
        download_url=$download_url
        expected_sha1=$sha1_hash
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

    echo "INFO - Downloading update..."

    wget -O "$destination_path" "$download_url" || (echo "ERROR - Downloading firmware was not successful" && exit 1)
}

main() {
    if [ "$EUID" -ne 0 ]; then
        echo "The OTA updater script should be run with root priviledges!"
        exit
    fi

    check_for_updates "$current_version" "$update_server_url"

    if $update_available; then
        echo "Update available! Current version: $current_version, Latest version: $latest_version"
        download_folder="/tmp"
        download_path="$download_folder/ota-firmware-update.bin"
        download_update "$download_url" "$download_path"

        # Checking SHA1 hash of downloaded firmware
        if check_sha1 "$download_path" "$expected_sha1"; then
            echo "Checking firmware integrity: OK"
        else
            echo "ERROR - Checking firmware integrity: FAIL"
            echo "Expected SHA1: $expected_sha1"
            echo "Actual SHA1: $(calculate_sha1 "$download_path")"
            exit 1
        fi

        # Updating firmware
        sysupgrade -c -v $download_path &
    else
        echo "No updates available. Current version: $current_version"
    fi
}

main
