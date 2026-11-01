# Initial Debian 12 server setup

This server runs other resources in the homelab.

## Prerequisites

Debian 12 is installed with SSH server enabled and root login disabled.

## Bootstrap SSH access

Run on the client:

```shell
ssh-keygen -t ed25519 -C "<email_or_comment>"
ssh-copy-id -i ~/.ssh/<generated_key_name> <user>@<servername>
```

Everything else is done via SSH from the client, unless explicitly stated otherwise.

```shell
ssh -i ~/.ssh/<generated_key_name> <user>@<servername>
```

## Update Debian

Install available updates before setting up the server:

```shell
sudo apt update
sudo apt full-upgrade
sudo reboot
```

After the server restarts, reconnect over SSH.

## Restrict password SSH access

```shell
sudo apt update
sudo apt install -y neovim
sudo nvim /etc/ssh/sshd_config
# Set this (uncommented):
# PasswordAuthentication no
sudo /usr/sbin/sshd -t && sudo systemctl restart ssh
```

Keep the current SSH session open and verify that you can connect in a second terminal before closing it.

## Use 4k 16:10 in terminal

This is optional. It is useful in case server console access and the monitor is high resolution.

```shell
sudo nvim /etc/default/grub
# Set these (uncommented):
# GRUB_GFXMODE=3840x2400
# GRUB_GFXPAYLOAD_LINUX=keep
sudo update-grub
sudo dpkg-reconfigure console-setup
# Select Terminux 16x32 font
sudo reboot
```

## Disable suspend and hibernation

```shell
sudo mkdir -p /etc/systemd/sleep.conf.d
sudo tee -a /etc/systemd/sleep.conf.d/nosuspend.conf <<EOF
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF
```

## Set MOTD

```shell
echo "" | sudo tee /etc/motd && echo "Welcome to $USER's home lab!" | sudo tee -a /etc/motd
```

## Install misc tools

```shell
sudo apt install -y fzf btop tree curl tldr
```

## Bash profile settings

```shell
cat >> ~/.bashrc<< EOF

# fzf completion and history search
source /usr/share/doc/fzf/examples/key-bindings.bash

# Custom aliases
alias la='ls -lah'
EOF
```

## Temperature sensors

```shell
sudo apt install -y lm-sensors
sudo sensors-detect --auto
```

## Disable swap

This is recommended for running Kubernetes.

```shell
sudo swapoff -a
systemctl --type=swap --all
# note the unit name, e.g. dev-XXXX.swap
sudo systemctl mask dev-XXXX.swap
sudo nvim /etc/fstab
# Comment out the lines referring to swap partitions
sudo reboot
```

## Install K3s

```shell
DOMAIN_NAME="example.com"
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s - --tls-san k8s.$DOMAIN_NAME
```

### Authorize K3s in Docker Hub

```shell
DOCKERHUB_USERNAME="example-user"
DOCKERHUB_TOKEN="dckr_pat_xxxx" # Create one at https://app.docker.com/settings/personal-access-tokens
sudo install -m 600 /dev/null /etc/rancher/k3s/registries.yaml
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
configs:
  registry-1.docker.io:
    auth:
      username: $DOCKERHUB_USERNAME
      password: $DOCKERHUB_TOKEN
EOF
sudo systemctl restart k3s
```

## Configure Kubernetes client access

Run this directly on the client to copy the kubeconfig file:

```shell
HOST="homelab"
SSH_USER="homelab-admin"
SSH_KEY="$HOME/.ssh/$HOST"
scp -i "$SSH_KEY" "$SSH_USER@$HOST:/etc/rancher/k3s/k3s.yaml" .
chmod 600 k3s.yaml
```

Feel free to save the coppied file as `~/.kube/config` (in this case, also run `chmod 600 ~/.kube/config`).  
Update the server URL in the config file.  
Now the Kubernetes cluster is accessible from the LAN. To make it accessible across the internet, proceed to [cloudflared setup](../cloudflared/README.md).
