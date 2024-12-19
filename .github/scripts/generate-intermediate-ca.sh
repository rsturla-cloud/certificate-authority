#!/usr/bin/env bash

set -euo pipefail

# Ensure the script is run with at least one argument
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-csr-json>"
  exit 1
fi

CSR_JSON_PATH="$1"
# Remove the extension from the CSR_JSON_PATH but keep the full path
CSR_WITHOUT_EXTENSION="${CSR_JSON_PATH%.*}"

# Ensure required commands are available
for cmd in cfssl cfssljson find; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: Required command '$cmd' is not installed. Please install it and try again."
    exit 1
  fi
done

# Check if the CSR JSON file exists
if [[ ! -f "$CSR_JSON_PATH" ]]; then
  echo "Error: CSR JSON file not found at path: '$CSR_JSON_PATH'"
  exit 1
fi

# Locate the configuration file
CONFIG_FILE_PATH=$(find . -type f -name "cfssl.json" | head -n 1)
if [[ -z "$CONFIG_FILE_PATH" ]]; then
  echo "Error: 'cfssl.json' configuration file not found in the current directory or its subdirectories."
  exit 1
fi

# Locate the intermediates directory
INTERMEDIATES_DIR=$(find . -type d -name "intermediates" | head -n 1)
if [[ -z "$INTERMEDIATES_DIR" ]]; then
  echo "Error: 'intermediates' directory not found in the current directory or its subdirectories."
  exit 1
fi

# Derive the root certificate directory
ROOT_CERT_DIR="$(dirname "$INTERMEDIATES_DIR")/root/certs"
if [[ ! -d "$ROOT_CERT_DIR" ]]; then
  echo "Error: Root certificate directory not found at '$ROOT_CERT_DIR'."
  exit 1
fi

if [[ ! -f "$ROOT_CERT_DIR/root-ca.pem" || ! -f "$ROOT_CERT_DIR/root-ca-key.pem" ]]; then
  echo "Error: Root CA PEM or Key file not found in '$ROOT_CERT_DIR'."
  exit 1
fi

# Generate the certificate
{
  cfssl gencert -initca "$CSR_JSON_PATH" | cfssljson -bare "$CSR_WITHOUT_EXTENSION"
} || {
  echo "Error: Failed to generate initial CA certificate."
  exit 1
}

# Sign the CSR with the root CA
{
  cfssl sign \
    -ca "$ROOT_CERT_DIR/root-ca.pem" \
    -ca-key "$ROOT_CERT_DIR/root-ca-key.pem" \
    -config "$CONFIG_FILE_PATH" \
    -profile intermediate \
    "$CSR_WITHOUT_EXTENSION.csr" | cfssljson -bare "$CSR_WITHOUT_EXTENSION"
} || {
  echo "Error: Failed to sign the CSR using the root CA."
  exit 1
}

echo "Certificate generation and signing completed successfully."
