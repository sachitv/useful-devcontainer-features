#!/bin/bash
set -e

updaterc() {
	if cat /etc/os-release | grep "ID_LIKE=.*alpine.*\|ID=.*alpine.*"; then
		echo "Updating /etc/profile"
		echo -e "$1" >>/etc/profile
	fi
	if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
		echo "Updating /etc/bash.bashrc"
		echo -e "$1" >>/etc/bash.bashrc
	fi
	if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
		echo "Updating /etc/zsh/zshrc"
		echo -e "$1" >>/etc/zsh/zshrc
	fi
}

sourcerc() {
	if cat /etc/os-release | grep "ID_LIKE=.*alpine.*\|ID=.*alpine.*"; then
		source /etc/profile
	fi
	if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
		source /etc/bash.bashrc
	fi
	if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
		source >>/etc/zsh/zshrc
	fi
}

check_alpine_packages() {
	apk add -v --no-cache "$@"
}

check_packages() {
	if ! dpkg -s "$@" >/dev/null 2>&1; then
		if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
			echo "Running apt-get update..."
			apt-get update -y
		fi
		DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends "$@"
		rm -rf /var/lib/apt/lists/*
	fi
}

maybe_setup_prerequisites() {
	if cat /etc/os-release | grep "ID_LIKE=.*alpine.*\|ID=.*alpine.*"; then
		check_alpine_packages curl git bash ca-certificates build-base libffi-dev openssl-dev bzip2-dev zlib-dev xz-dev readline-dev sqlite-dev tk-dev
	elif cat /etc/os-release | grep "ID_LIKE=.*debian.*\|ID=.*debian.*"; then
		check_packages curl git ca-certificates build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
	fi
}

remove_duplicates() {
    local input_array=("$@")  # Create a local copy of the input array
    local unique_array=()     # Initialize an empty array to store unique values

    for value in "${input_array[@]}"; do
        if [[ ! " ${unique_array[@]} " =~ " $value " ]]; then
            unique_array+=("$value")  # Add the value to the unique array if it's not already present
        fi
    done

    echo "${unique_array[@]}"  # Output the unique values
}

# Read the versions string.
readarray -td, versions_arr <<<"$VERSIONS"

if [ "${#versions_arr[@]}" -eq 0 ]; then
	echo "No versions specified. Exiting."
	exit 1
fi

maybe_setup_prerequisites

# Setup Paths
export PYENV_ROOT="/opt/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Install PyEnv.
curl https://pyenv.run | bash

# Add PyEnv to bashrc.
updaterc 'export PYENV_ROOT="/opt/.pyenv"'
updaterc 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"'
updaterc 'eval "$(pyenv init -)"'
sourcerc

# Remove duplicates while preserving the order.
unique_versions=$(remove_duplicates "${versions_arr[@]}")

for version in "${unique_versions[@]}"; do
    pyenv install ${version}
done

# Set the first value as the default.
pyenv local ${unique_versions[0]}
