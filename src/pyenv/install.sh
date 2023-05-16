#!/bin/bash
set -e

# Setup Paths
export PYENV_ROOT="/opt/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Install PyEnv.
curl https://pyenv.run | bash

# Add PyEnv to the path.
echo 'export PYENV_ROOT="/opt/.pyenv"' >> /etc/bash.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> /etc/bash.bashrc
echo 'eval "$(pyenv init -)"' >> /etc/bash.bashrc

# Install the latest version of Python.
pyenv install ${DEFAULT}
