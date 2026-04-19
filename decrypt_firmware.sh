#!/bin/bash
# Philips TWA6505 / Phorus Caprica5 Firmware Decryption Script
#
# Flash security block layout (found at 0x162c000 in flash_dump.bin, in 'see' partition):
#   +0x38: MAC address string (hex format)
#   +0x58: FIRMWARE DECRYPTION PASSWORD (UUID-format 36-char string)
#   +0x98: Update server auth password / UPWD (16-char alphanumeric string)
#   +0xd8: Device TLS certificate (PEM)
#   +0x11f8: Encrypted device private key (PEM)
#
# Usage: ./decrypt_firmware.sh <flash_dump.bin> <factorytest0.zip> <output.zip>

set -e

FLASH_DUMP="${1:-flash_dump.bin}"
ENCRYPTED_PACKAGE="${2:-factorytest0.zip}"
OUTPUT="${3:-firmware_decrypted.zip}"

if [ ! -f "$FLASH_DUMP" ]; then
    echo "ERROR: Flash dump not found: $FLASH_DUMP"; exit 1
fi
if [ ! -f "$ENCRYPTED_PACKAGE" ]; then
    echo "ERROR: Encrypted package not found: $ENCRYPTED_PACKAGE"; exit 1
fi

echo "=== Philips TWA6505 Firmware Decryption Tool ==="

# Extract decryption password from flash security partition
echo "[1] Extracting decryption password from flash..."
PASSWORD=$(python3 -c "
import struct, sys
data = open('$FLASH_DUMP','rb').read()
for base in [0x162c000, 0x164d000]:
    magic = struct.unpack_from('<I', data, base)[0]
    if magic == 0x00020000:
        pwd_raw = data[base+0x58:base+0xb8]
        pwd = pwd_raw.split(b'\x00')[0].decode('ascii', errors='replace')
        if len(pwd) > 10:
            print(pwd); sys.exit(0)
print('ERROR: Security block not found', file=sys.stderr); sys.exit(1)
")

echo "    Password: ${PASSWORD}"

# Decrypt
echo "[2] Decrypting with OpenSSL BF-CBC / MD5..."
openssl enc -bf-cbc -d -md md5 \
    -provider legacy -provider default \
    -pass "pass:${PASSWORD}" \
    -in "$ENCRYPTED_PACKAGE" \
    -out "$OUTPUT" 2>/dev/null

echo "[3] Firmware contents:"
unzip -l "$OUTPUT"

echo ""
echo "To extract: unzip '$OUTPUT' -d firmware_contents -x '*.ubi' -x '*.ubo'"
