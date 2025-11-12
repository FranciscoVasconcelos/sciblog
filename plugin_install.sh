
#!/usr/bin/env bash

# ==========================================================
# Install selected parts of the sciblog repository
# Downloads `_plugin/` and `bin/` directories only.
# ==========================================================

set -e

# --- Configuration ---
REPO_URL="https://github.com/FranciscoVasconcelos/sciblog.git"
BRANCH="main"   # change if needed
DEST_DIR="${1:-./sciblog_parts}"  # default target directory (can pass as first arg)

# --- Setup temporary directory ---
TMP_DIR=$(mktemp -d)
echo "Cloning repository sparsely into: $TMP_DIR"

# --- Clone only specific folders ---
git clone --depth 1 --no-checkout "$REPO_URL" "$TMP_DIR" > /dev/null 2>&1
cd "$TMP_DIR"

git sparse-checkout init --cone > /dev/null 2>&1
git sparse-checkout set _plugins bin > /dev/null 2>&1
git checkout "$BRANCH" > /dev/null 2>&1

# --- Move desired folders to destination ---
mkdir -p "$DEST_DIR"
mv _plugins "$DEST_DIR"/
mv bin "$DEST_DIR"/

cd -
rm -rf "$TMP_DIR"

echo "Installation completed."
echo "Downloaded folders are now in: $DEST_DIR"
