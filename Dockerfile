FROM ubuntu:22.04

# -----------------------------
# Install required packages
# -----------------------------
RUN apt update && apt install -y \
    openssh-server \
    curl \
    wget \
    unzip \
    sudo \
    python3 \
    ca-certificates \
    gnupg \
    iptables \
    && mkdir /var/run/sshd

# -----------------------------
# Create user 'trthaodev' with sudo
# -----------------------------
RUN useradd -m trthaodev && echo "trthaodev:thaodev@" | chpasswd && adduser trthaodev sudo

# -----------------------------
# Configure SSH
# -----------------------------
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config && \
    echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config

# -----------------------------
# Install Tailscale
# -----------------------------
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && \
    apt-get install -y tailscale

# -----------------------------
# Copy start script
# -----------------------------
COPY start-tailscale-ssh.sh /usr/local/bin/start-tailscale-ssh.sh
RUN chmod +x /usr/local/bin/start-tailscale-ssh.sh

# -----------------------------
# Expose ports
# -----------------------------
# Web server for Railway/Render keep-alive
EXPOSE 8080
# SSH
EXPOSE 22
# Optional ports for aaPanel or FTP
EXPOSE 14489 888 80 443 20 21

# -----------------------------
# Start container
# -----------------------------
CMD ["/usr/local/bin/start-tailscale-ssh.sh"]
