# OpenWRT OTA Updater
 The script checks if there's a new version of firmware avaible. If update is available, it downloads new firmware and carries out sysupgrade.

## Configuration
Please update `update_server_url` in `ota-updater.sh` according to your requirements.

## Server response
It should be a plain text response with 200 code. An example is provided in `server/check_updates`:

```
version=1
download_url="http://localhost:8000/firmware-1.1.bin"
sha1_hash="da39a3ee5e6b4b0d3255bfef95601890afd80709"
```

# Limitations
**Version number should be an integer (e.g 1, 2, 3)!**

Version number like 1.0 or 1.0.1 are NOT SUPPORTED.
