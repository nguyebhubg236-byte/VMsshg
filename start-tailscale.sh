#!/bin/bash

echo "=== Starting SSH service ==="
service ssh start

# Check Tailscale auth key
if [ -z "$TAILSCALE_AUTHKEY" ]; then
    echo "⚠️  Error: TAILSCALE_AUTHKEY not found!"
    echo "➡️  Create an auth key at: https://login.tailscale.com/admin/settings/keys"
    echo "➡️  Then set environment variable: TAILSCALE_AUTHKEY=tskey-auth-..."
    exit 1
fi

# Create directories for Tailscale
mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Start Tailscale daemon
echo "=== Starting Tailscale daemon ==="
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
sleep 3

# Connect to Tailscale network
echo "=== Connecting to Tailscale network ==="
tailscale up --authkey="$TAILSCALE_AUTHKEY" --ssh --hostname="ssh-aapanel-server"

# Wait for connection
sleep 3

# Get Tailscale information
TAILSCALE_IP=$(tailscale ip -4)
TAILSCALE_HOSTNAME=$(tailscale status --json | grep -o '"HostName":"[^"]*"' | cut -d'"' -f4)

# Detect aaPanel port dynamically
AAPANEL_PORT=$(cat /www/server/panel/data/port.pl 2>/dev/null || echo 8888)
echo "Detected aaPanel port: $AAPANEL_PORT"

if [ -n "$TAILSCALE_IP" ]; then
  echo "✅ Tailscale connected successfully!"
  echo ""
  echo "=== SSH Connection Info ==="
  echo "Tailscale IP: $TAILSCALE_IP"
  if [ -n "$TAILSCALE_HOSTNAME" ]; then
    echo "Hostname: $TAILSCALE_HOSTNAME"
    echo ""
    echo "Connect via SSH:"
    echo "  ssh trthaodev@$TAILSCALE_IP"
    echo "  ssh trthaodev@$TAILSCALE_HOSTNAME"
  else
    echo ""
    echo "Connect via SSH:"
    echo "  ssh trthaodev@$TAILSCALE_IP"
  fi
  
  echo ""
  echo "=== aaPanel Access Info ==="
  echo "Access aaPanel at:"
  echo "  http://$TAILSCALE_IP:$AAPANEL_PORT"
  if [ -n "$TAILSCALE_HOSTNAME" ]; then
    echo "  http://$TAILSCALE_HOSTNAME:$AAPANEL_PORT"
  fi
  
  echo ""
  echo "Password: thaodev@"
  echo ""
  echo "📱 Note: Install Tailscale on your client device and login with"
  echo "    the same account to access this server."
else
  echo "⚠️  Failed to get Tailscale IP"
  echo "Check status for details:"
  tailscale status
fi

# Keep container alive
echo ""
echo "=== Starting keep-alive web service (port 8080) ==="
python3 -m http.server 8080 >/dev/null 2>&1 &
echo "Container keep-alive running on port 8080."

# Keep script running
tail -f /dev/null
