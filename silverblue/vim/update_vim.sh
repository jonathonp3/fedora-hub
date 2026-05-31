#!/bin/bash

# Configuration
CONTAINER_NAME="vim-builder"
VIM_SRC_DIR="$HOME/vim-source"
BINARY_PATH="/usr/local/bin/vim"

echo "🔍 Checking for Vim updates..."

# 1. Get the current local version (Patch number)
if [ -f "$BINARY_PATH" ]; then
    CURRENT_VERSION=$(vim --version | head -n 1 | grep -oP '\d+\.\d+')
    CURRENT_PATCH=$(vim --version | head -n 3 | grep -oP 'Included patches: \d+-\K\d+')
    echo "✅ Local version: $CURRENT_VERSION (Patch $CURRENT_PATCH)"
else
    echo "❌ Local Vim not found in $BINARY_PATH. Starting fresh install..."
    CURRENT_PATCH=0
fi

# 2. Get the latest version from GitHub
echo "🌐 Fetching latest version from GitHub..."
LATEST_PATCH=$(git ls-remote --tags https://github.com/vim/vim.git | grep -oP 'v\d+\.\d+\.\K\d+$' | sort -n | tail -n 1)

if [ -z "$LATEST_PATCH" ]; then
    echo "⚠️  Could not reach GitHub. Check your internet connection."
    exit 1
fi

echo "✨ Latest available patch: $LATEST_PATCH"

# 3. Compare versions
if [ "$LATEST_PATCH" -le "$CURRENT_PATCH" ]; then
    echo "😎 Vim is already up to date. No action needed."
    exit 0
fi

echo "🚀 Update required! (Patch $CURRENT_PATCH -> $LATEST_PATCH)"

# 4. Prepare the Toolbox
if ! toolbox list | grep -q "$CONTAINER_NAME"; then
    echo "📦 Creating builder toolbox..."
    toolbox create -c $CONTAINER_NAME -y
    toolbox run -c $CONTAINER_NAME sudo dnf install -y git gcc make ncurses-devel python3-devel
fi

# 5. Pull and Compile
echo "🔨 Compiling new version (this may take a minute)..."
if [ ! -d "$VIM_SRC_DIR" ]; then
    git clone https://github.com/vim/vim.git "$VIM_SRC_DIR"
fi

toolbox run -c $CONTAINER_NAME bash -c "
    cd $VIM_SRC_DIR && \
    git fetch --all && \
    git reset --hard origin/master && \
    ./configure --with-features=huge \
                --enable-python3interp=yes \
                --enable-multibyte \
                --prefix=/usr/local && \
    make -j$(nproc)
"

# 6. Install to Host (Preserving your settings)
echo "📂 Deploying to /usr/local..."

# Backup binary just in case
sudo cp /usr/local/bin/vim /usr/local/bin/vim.bak 2>/dev/null

# Install new binary
sudo cp "$VIM_SRC_DIR/src/vim" /usr/local/bin/vim
sudo chmod +x /usr/local/bin/vim

# Update runtime files 
# (This adds new syntax/features but won't delete your /usr/local/share/vim/vimrc)
sudo mkdir -p /usr/local/share/vim
sudo cp -r "$VIM_SRC_DIR/runtime/"* /usr/local/share/vim/

# Cleanup
hash -r

echo "✅ Vim successfully updated to Patch $LATEST_PATCH!"
echo "🎨 Your themes and global vimrc remain active."

