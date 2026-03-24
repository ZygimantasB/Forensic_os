#!/bin/bash
# Prepare the chroot includes directory with our forensic tools
# This copies tools, lib, ui, templates, and configs into the live filesystem overlay
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INCLUDES_DIR="$PROJECT_ROOT/config/live-build/config/includes.chroot"

echo "[PREP] Preparing chroot overlay..."

# Create directories
mkdir -p "$INCLUDES_DIR/opt/forensic-os"/{tools,lib,ui,templates,config}
mkdir -p "$INCLUDES_DIR/usr/local/bin"
mkdir -p "$INCLUDES_DIR/etc/udev/rules.d"

# Copy tools
echo "[PREP] Copying forensic tools..."
cp -a "$PROJECT_ROOT/tools"/forensic-* "$INCLUDES_DIR/opt/forensic-os/tools/"
chmod +x "$INCLUDES_DIR/opt/forensic-os/tools"/*

# Copy library
echo "[PREP] Copying shared library..."
cp -a "$PROJECT_ROOT/lib"/forensic-common.sh "$INCLUDES_DIR/opt/forensic-os/lib/"

# Copy UI
echo "[PREP] Copying UI launchers..."
cp -a "$PROJECT_ROOT/ui"/forensic-launcher "$INCLUDES_DIR/opt/forensic-os/ui/"
cp -a "$PROJECT_ROOT/ui"/forensic-gui "$INCLUDES_DIR/opt/forensic-os/ui/"
chmod +x "$INCLUDES_DIR/opt/forensic-os/ui"/*

# Copy templates
echo "[PREP] Copying report templates..."
cp -a "$PROJECT_ROOT/templates"/*.html "$INCLUDES_DIR/opt/forensic-os/templates/"

# Copy udev rules
echo "[PREP] Copying udev write-block rules..."
cp -a "$PROJECT_ROOT/config/udev/99-forensic-writeblock.rules" "$INCLUDES_DIR/etc/udev/rules.d/"

# Copy desktop file
if [ -f "$PROJECT_ROOT/ui/desktop/forensic-os.desktop" ]; then
    mkdir -p "$INCLUDES_DIR/usr/share/applications"
    cp -a "$PROJECT_ROOT/ui/desktop/forensic-os.desktop" "$INCLUDES_DIR/usr/share/applications/"
fi

echo "[PREP] Chroot overlay prepared successfully."
echo "[PREP] Contents of /opt/forensic-os in ISO:"
find "$INCLUDES_DIR/opt/forensic-os" -type f | sort | sed 's|.*includes.chroot||'
