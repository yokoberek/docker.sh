#!/bin/bash
set -e

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        UBUNTU_CODENAME=$UBUNTU_CODENAME
        VERSION_CODENAME=$VERSION_CODENAME
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
        UBUNTU_CODENAME=$DISTRIB_CODENAME
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        OS=$(awk '{print tolower($1)}' /etc/redhat-release)
        VER=$(awk '{print $3}' /etc/redhat-release)
    elif [ -f /etc/centos-release ]; then
        OS="centos"
        VER=$(awk '{print $4}' /etc/centos-release)
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        VER=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi

    # Convert OS to lowercase
    OS=$(echo "$OS" | tr '[:upper:]' '[:lower:]')

    # Handle OS aliases
    case "$OS" in
        "rhel"|"ol"|"centos"|"rocky"|"almalinux")
            OS="rhel"
            ;;
        "ubuntu"|"pop"|"elementary"|"linuxmint"|"zorin"|"neon")
            OS="ubuntu"
            ;;
        "debian"|"kali"|"raspbian")
            OS="debian"
            ;;
        "fedora"|"nobara")
            OS="fedora"
            ;;
    esac

    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armhf"
            ;;
    esac

    # Detect package manager
    if command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt-get"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    else
        PKG_MANAGER="unknown"
    fi
}

# Function to install Docker on CentOS
install_centos() {
    echo "Uninstalling old versions..."
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

    echo "Setting up Docker repository..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    echo "Installing Docker Engine..."
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Starting Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker

    echo "Verifying installation..."
    sudo docker run hello-world
}

# Function to install Docker on Debian/Ubuntu
install_debian_ubuntu() {
    echo "Uninstalling old versions..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

    echo "Setting up Docker repository..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    echo "Installing Docker Engine..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Verifying installation..."
    sudo docker run hello-world
}

# Function to install Docker on Fedora
install_fedora() {
    echo "Uninstalling old versions..."
    sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine

    echo "Setting up Docker repository..."
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

    echo "Installing Docker Engine..."
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Starting Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker

    echo "Verifying installation..."
    sudo docker run hello-world
}

# Function to install Docker on RHEL
install_rhel() {
    echo "Uninstalling old versions..."
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc

    echo "Setting up Docker repository..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

    echo "Installing Docker Engine..."
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Starting Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker

    echo "Verifying installation..."
    sudo docker run hello-world
}

# Detect the OS
detect_os

echo "Detected OS: $OS"
echo "Detected Version: $VER"
echo "Detected Architecture: $ARCH"
echo "Package Manager: $PKG_MANAGER"
[ -n "$UBUNTU_CODENAME" ] && echo "Ubuntu Codename: $UBUNTU_CODENAME"
[ -n "$VERSION_CODENAME" ] && echo "Version Codename: $VERSION_CODENAME"

# Install Docker based on detected OS
case "$OS" in
    centos)
        install_centos
        ;;
    debian|ubuntu)
        install_debian_ubuntu
        ;;
    fedora)
        install_fedora
        ;;
    rhel)
        install_rhel
        ;;
    *)
        echo "Unsupported operating system: $OS"
        exit 1
        ;;
esac

echo "Docker installation completed successfully."

# Add current user to docker group
if getent group docker > /dev/null 2>&1; then
    sudo usermod -aG docker $USER
    echo "Added current user to the docker group. You may need to log out and back in for this to take effect."
else
    echo "Docker group doesn't exist. You may need to create it manually or reinstall Docker."
fi

echo "Please log out and log back in to apply group changes, or run 'newgrp docker' to update group assignments for the current session."
