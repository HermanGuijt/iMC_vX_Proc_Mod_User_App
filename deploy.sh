#!/bin/bash
#
# Deployment script for qtphy to iMC vX board
# This script handles the complete deployment workflow including
# Wayland socket recreation to avoid display issues
#

set -e  # Exit on error

# ════════════════════════════════════════════════════════════════════════════
# Configuration
# ════════════════════════════════════════════════════════════════════════════

BOARD_IP="192.168.178.206"
BOARD_USER="root"
BINARY_PATH="build/qtphy"
DEPLOY_PATH="/usr/bin/qtphy"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ════════════════════════════════════════════════════════════════════════════
# Helper Functions
# ════════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ssh_exec() {
    ssh "${BOARD_USER}@${BOARD_IP}" "$1"
}

# ════════════════════════════════════════════════════════════════════════════
# Main Deployment Workflow
# ════════════════════════════════════════════════════════════════════════════

echo "════════════════════════════════════════════════════════════════════"
echo "  qtphy Deployment Script"
echo "  Target: ${BOARD_USER}@${BOARD_IP}"
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Check if binary exists
log_info "Checking if binary exists..."
if [ ! -f "${BINARY_PATH}" ]; then
    log_error "Binary not found: ${BINARY_PATH}"
    log_info "Please build the project first using: meson compile -C build"
    exit 1
fi
log_success "Binary found: ${BINARY_PATH}"

# Step 2: Check board connectivity
log_info "Checking board connectivity..."
if ! ping -c 1 -W 2 "${BOARD_IP}" > /dev/null 2>&1; then
    log_error "Board is not reachable at ${BOARD_IP}"
    exit 1
fi
log_success "Board is reachable"

# Step 3: Stop qtphy service
log_info "Stopping qtphy service on board..."
ssh_exec 'systemctl stop qtphy.service 2>/dev/null || pkill qtphy 2>/dev/null || true'
sleep 1
log_success "qtphy service stopped"

# Step 4: Restart Weston (fixes Wayland socket issues)
log_info "Restarting Weston compositor (fixes Wayland display socket)..."
ssh_exec 'systemctl restart weston.service'
sleep 3  # Give Weston time to create the socket
log_success "Weston restarted"

# Step 5: Verify Wayland socket exists
log_info "Verifying Wayland socket..."
if ! ssh_exec 'test -S /run/user/0/wayland-1'; then
    log_warning "Wayland socket not found, waiting 2 more seconds..."
    sleep 2
    if ! ssh_exec 'test -S /run/user/0/wayland-1'; then
        log_error "Wayland socket still not available after Weston restart"
        log_info "Manual intervention may be required"
        exit 1
    fi
fi
log_success "Wayland socket is available"

# Step 6: Deploy binary
log_info "Deploying binary to board..."
scp -q "${BINARY_PATH}" "${BOARD_USER}@${BOARD_IP}:${DEPLOY_PATH}"
log_success "Binary deployed to ${DEPLOY_PATH}"

# Step 7: Verify service configuration
log_info "Verifying qtphy service configuration..."
SERVICE_CONFIG="[Unit]
Description=Qt6 Demo Application (qtphy)
Requires=weston.service
After=weston.service

[Service]
Environment=XDG_RUNTIME_DIR=/run/user/0
Environment=WAYLAND_DISPLAY=wayland-1
Environment=QT_QPA_PLATFORM=wayland
Environment=QT_SCALE_FACTOR=1
Environment=QT_AUTO_SCREEN_SCALE_FACTOR=0
Environment=QT_SCREEN_SCALE_FACTORS=1
ExecStart=/usr/bin/qtphy
User=root
WorkingDirectory=/root
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target"

ssh_exec "cat > /etc/systemd/system/qtphy.service << 'EOF'
${SERVICE_CONFIG}
EOF"
log_success "Service configuration verified/updated"

# Step 8: Reload systemd and start service
log_info "Reloading systemd daemon..."
ssh_exec 'systemctl daemon-reload'
log_success "Systemd daemon reloaded"

log_info "Starting qtphy service..."
ssh_exec 'systemctl start qtphy.service'
sleep 2

# Step 9: Check service status
log_info "Checking service status..."
if ssh_exec 'systemctl is-active --quiet qtphy.service'; then
    log_success "qtphy service is running!"
    
    # Show brief status
    echo ""
    echo "Service Status:"
    ssh_exec 'systemctl status qtphy.service --no-pager -l | head -15' || true
    
    echo ""
    log_success "✅ Deployment completed successfully!"
    log_info "Application should now be visible on the display"
    log_info "CAN logs location: /tmp/can_log_*.csv"
else
    log_error "qtphy service failed to start"
    echo ""
    echo "Recent logs:"
    ssh_exec 'journalctl -u qtphy.service -n 20 --no-pager' || true
    exit 1
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "  Deployment complete"
echo "════════════════════════════════════════════════════════════════════"
