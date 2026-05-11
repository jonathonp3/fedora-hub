# Full Vim Installation (Catppuccin Edition) for Fedora Silverblue
## Overview

This guide builds and installs Vim from source inside a Toolbox container, then installs the binary and runtime files to /usr/local on the host. This ensures that both your standard user and sudo commands use the same high-performance, full-featured Vim.
Prerequisites

    Fedora Silverblue
    Toolbox installed
    Sudo privileges on the host

Step-by-Step Installation

1. Prepare the Build Environment

Create and enter a dedicated toolbox:
```bash
toolbox create vim-build
toolbox enter vim-build
```
Install the required libraries and compilers:
```bash
sudo dnf install -y git gcc make ncurses-devel python3-devel
```

2. Build Vim from Source

Clone the latest source code:
```bash
git clone https://github.com/vim/vim.git
cd ~/vim
```
Run the "Huge" configuration (enables Python3, Multi-byte, and all advanced features):
bash

./configure --with-features=huge \
            --enable-python3interp=yes \
            --enable-multibyte \
            --prefix=/usr/local

Compile using all available CPU cores:
```bash
make -j$(nproc)
```
Exit the toolbox:
```bash
exit
```

3. Install to the Host (Global)

These commands are run on your host terminal to move the files into the persistent /usr/local area.
bash

Create the binary directory
```bash
sudo mkdir -p /usr/local/bin/
```

Copy the compiled binary
```bash
sudo cp ~/vim/src/vim /usr/local/bin/vim
sudo chmod +x /usr/local/bin/vim
```

Create and copy the runtime (syntax, colors, etc.)
```bash
sudo mkdir -p /usr/local/share/vim
sudo cp -r ~/vim/runtime/* /usr/local/share/vim/
```

Refresh the host path cache
```bash
hash -r
```

Configuration & Themes
The Global Configuration (Sudo/Default)

Create the global settings file for all users:
```bash
sudo vi /usr/local/share/vim/vimrc
```

Add the following to the file:
```bash
" Enable features for all users
set nocompatible
syntax on
set termguicolors
set background=dark

" Set the global default theme
colorscheme catppuccin

" Quality of life settings
set number
set backspace=indent,eol,start
```

User Configuration

Create your personal settings:
```bash
vim ~/.vimrc
```
Add your baseline settings:
```bash
set nocompatible
syntax on
set termguicolors
set background=dark
colorscheme catppuccin
set number
set clipboard=unnamedplus
```
Verification

To ensure everything is working correctly, run:

    which vim — should return /usr/local/bin/vim.
    vim --version — should show Huge version and Compiled by [your-username]@toolbx.
    sudo vim /etc/fstab — should display with full Catppuccin colors and line numbers.

Included Colorschemes

    
To change the local theme:
```bash
vim ~/.vimrc
```

Example set unokai:
```bash
colorscheme unokai
```

These themes are installed system-wide in 
```bash
ls -l /usr/local/share/vim/colors/
```

    🎨 Included Vim Colorschemes

🌟 Recommended Modern Themes

    catppuccin (Current System Default) - High-end pastel dark theme.
    unokai - Vibrant neon theme based on Monokai.
    retrobox - Warm, Gruvbox-inspired palette.
    habamax - The clean, professional Vim 9 default.

🟢 High-Contrast & "Hacker" Themes

    torte - High-contrast black with vivid green text.
    industry - Professional dark theme with mint/teal accents.
    ron - Dark background with neon-bright highlights.
    elflord - Classic high-contrast cyan and green.

🏛️ The Great Classics

    desert - The legendary, low-strain grey/brown theme.
    evening - Soft blue-grey dark theme.
    slate - Deep grey and blood-orange tones.
    darkblue / blue - Traditional blue-background themes.
    delek / koehler / pablo - Legacy favorites.

☀️ Light Themes (Daylight Mode)

    morning - Clean, grey-white light theme.
    shine - Bright, crisp white background.
    peachpuff - Soft, warm light theme.
    quiet - Minimalist, low-distraction layout.

🛠️ Specialty & Other

    lunaperche - A versatile modern theme that adapts well.
    sorbet - Vibrant and colorful.
    wildcharm / zaibatsu / zellner - Unique aesthetic variations.
    default - The standard, unflavored Vim look.

How to browse them in real-time

You can cycle through these themes in your terminal by typing:
vim

:colorscheme [Space] [Tab]

Powered by a Native Huge Build of Vim 9.2+ on Fedora 44.



