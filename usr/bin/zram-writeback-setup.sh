#!/usr/bin/env bash

# This is a simple helper script to setup a zram device with writeback support.
# It creates a zram-generator.conf file to configure the zram device for
# writeback, and restarts systemd-zram-generator service to apply the changes.
# Then it enables the zram-writeback-*@.timers.

usage() {
  printf "Usage: %s [-z zram_device] [-w writeback_device] [-c compression_algorithm]\n\n" "${0}"
  printf "Options:\n"
  printf "  -z \tSpecify the zram device (default: zram0)\n"
  printf "  -w \tSpecify the writeback device (default: /dev/disk/by-label/swap)\n"
  printf "  -c \tSpecify the compression algorithm (default: zstd)\n"
  exit 1
}

while getopts "zwc:" flag; do
  case "${flag}" in
    z)
      ZRAM_DEV="${OPTARG}"
      ;;
    w)
      WRITEBACK_DEV="${OPTARG}"
      ;;
    c)
      COMPRESSION_ALGO="${OPTARG}"
      ;;
    *)
      usage
      ;;
  esac
done

echo "Creating /etc/systemd/zram-generator.conf for ${ZRAM_DEV:-zram0}..."

cat <<EOF | sudo tee /etc/systemd/zram-generator.conf
[${ZRAM_DEV:-zram0}]
zram-size = min(ram * 0.75, 12288)
compression-algorithm = ${COMPRESSION_ALGO:-zstd}
writeback-device=${WRITEBACK_DEV:-/dev/disk/by-label/swap}
EOF

echo "Restarting systemd-zram-generator service..."

systemctl restart systemd-zram-generator@"${ZRAM_DEV:-zram0}"

echo "Enabling zram-writeback timers for ${ZRAM_DEV:-zram0}..."

systemctl enable --now zram-writeback-idle@"${ZRAM_DEV:-zram0}".timer
systemctl enable --now zram-writeback-trigger@"${ZRAM_DEV:-zram0}".timer
systemctl enable --now zram-writeback-limit@"${ZRAM_DEV:-zram0}".timer

echo "Zram device ${ZRAM_DEV:-zram0} with writeback support has been configured."
