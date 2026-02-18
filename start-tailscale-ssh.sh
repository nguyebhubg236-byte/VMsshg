#!/bin/bash
echo "=== Bắt đầu dịch vụ SSH ==="
service ssh start

# Kiểm tra biến môi trường TAILSCALE_AUTHKEY
if [ -z "$TAILSCALE_AUTHKEY" ]; then
  echo "⚠️  Không tìm thấy biến môi trường TAILSCALE_AUTHKEY!"
  echo "➡️  Hãy tạo auth key tại: https://login.tailscale.com/admin/settings/keys"
  echo "➡️  Sau đó thêm vào môi trường container: TAILSCALE_AUTHKEY=tskey-auth-..."
  exit 1
fi

# Tạo thư mục state cho Tailscale
mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Khởi động Tailscale daemon
echo "=== Khởi động Tailscale daemon ==="
tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &
sleep 3

# Kết nối với Tailscale network
echo "=== Kết nối với Tailscale network ==="
tailscale up --authkey="$TAILSCALE_AUTHKEY" --ssh --hostname="ssh-server"

# Kiểm tra trạng thái và hiển thị thông tin
echo "=== Đang kiểm tra trạng thái Tailscale ==="
sleep 3

TAILSCALE_IP=$(tailscale ip -4)
TAILSCALE_HOSTNAME=$(tailscale status --json | grep -o '"HostName":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TAILSCALE_IP" ]; then
  echo "✅ Kết nối Tailscale thành công!"
  echo "=== Thông tin kết nối SSH ==="
  echo "Tailscale IP: $TAILSCALE_IP"
  if [ -n "$TAILSCALE_HOSTNAME" ]; then
    echo "Hostname: $TAILSCALE_HOSTNAME"
    echo ""
    echo "Kết nối SSH bằng một trong các cách sau:"
    echo "  ssh trthaodev@$TAILSCALE_IP"
    echo "  ssh trthaodev@$TAILSCALE_HOSTNAME"
  else
    echo ""
    echo "Kết nối SSH:"
    echo "  ssh trthaodev@$TAILSCALE_IP"
  fi
  echo ""
  echo "Mật khẩu: thaodev@"
  echo ""
  echo "📱 Lưu ý: Bạn cần cài đặt Tailscale trên máy client và đăng nhập cùng tài khoản"
  echo "    để có thể kết nối đến server này."
else
  echo "⚠️  Không thể lấy IP của Tailscale"
  echo "Kiểm tra log để biết thêm chi tiết:"
  tailscale status
fi

# Giữ container chạy bằng web service dummy
echo ""
echo "=== Giữ container hoạt động bằng web service ảo (port 8080) ==="
python3 -m http.server 8080
