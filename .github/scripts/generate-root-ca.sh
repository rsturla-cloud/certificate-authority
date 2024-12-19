#!/usr/bin/env bash

set -euo pipefail

# Ensure the script is run with at least one argument
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path-to-csr-json>"
  exit 1
fi

CSR_JSON_PATH="$1"
CSR_WITHOUT_EXTENSION=$(basename "$CSR_JSON_PATH" .json)

# Check if the CSR JSON file exists
if [[ ! -f "$CSR_JSON_PATH" ]]; then
  echo "Error: CSR JSON file not found at path: '$CSR_JSON_PATH'"
  exit 1
fi

# Check if cfssl is installed
if ! command -v cfssl &>/dev/null; then
  echo "Error: 'cfssl' command not found. Please install cfssl to continue."
  exit 1
fi

# Check if cfssljson is installed
if ! command -v cfssljson &>/dev/null; then
  echo "Error: 'cfssljson' command not found. Please install cfssljson to continue."
  exit 1
fi

# Generate certificate using cfssl and cfssljson
{
  cfssl gencert -initca "$CSR_JSON_PATH" | cfssljson -bare "$CSR_WITHOUT_EXTENSION"
} || {
  echo "Error: Failed to generate certificate using cfssl/cfssljson."
  exit 1
}

echo "Certificate generation completed successfully."
