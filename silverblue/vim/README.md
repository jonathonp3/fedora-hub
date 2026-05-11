# Full Vim Installation (catppuccin Edition) for Fedora Silverblue (Toolbox)
Overview

This guide builds and installs Vim from source inside a Toolbox container, then installs the binary and runtime files to /usr/local on the host so both your user and sudo see the same Vim. It also creates .vimrc files that enable True Color and set the Catppuccin/Unokai-like theme.
Prerequisites

    Fedora Silverblue with toolbox installed
    sudo privileges on the host
    Internet access

Step-by-step

Create and prepare the Toolbox
```bash
toolbox create vim-build
```

Enter toolbox
```bash
toolbox enter vim-build
```
Install libraries
```bash
sudo dnf install -y git gcc make ncurses-devel python3-devel
```

Clone or update Vim source
```bash
git clone https://github.com/vim/vim.git
```

Enter the source folder:
```bash
cd ~/vim
```

Run the configuration (The "Huge" setup):
```bash
./configure --with-features=huge \
            --enable-python3interp=yes \
            --enable-multibyte \
            --prefix=/usr/local
```
Compile:
```bash
make -j$(nproc)
```

Exit toolbox
```bash
exit
```

Create bin directory
```bash
sudo mkdir -p /usr/local/bin/
```

Copy the compiled 'Huge' Vim binary from your source folder to the system path
```bash
sudo cp ~/vim/src/vim /usr/local/bin/vim
```

Ensure the global shared directory exists for Vim's assets (colors, syntax, etc.)
```bash
sudo mkdir -p /usr/local/share/vim
```

Copy all runtime files (the 'brains' of Vim) to the global share directory
This allows 'sudo vim' and all users to access colorschemes and syntax highlighting
```bash
sudo cp -r ~/vim/runtime/* /usr/local/share/vim/
```

Make sure the binary has permission to execute as a program
```bash
sudo chmod +x /usr/local/bin/vim
```

Tell the terminal to clear its path cache so it 'sees' Vim immediately
```bash
hash -r
```

```

What nocompatible unlocks
When you set nocompatible, you are saying "I want the full power of Vim." It enables:
Multi-level undo (hitting u multiple times).
Better Backspace behavior (allowing you to backspace over line breaks).
Plugins and Scripts (which almost all require nocompatible mode).
Advanced command completion (using the Tab key in the command bar).


Check colour scheme in vim
```bash
vim
:echo g:colors_name
```

Create personal Vim configuration file
```bash
vim ~/.vimrc
```

The "Override" Rule

Vim follows a strict order. If a setting exists in both files, the last one read wins.

    First: Vim reads /usr/local/share/vim/vimrc (Global).
    Second: Vim reads ~/.vimrc (User).


Final Host Setup

Verify the installation:

    which vim should return /usr/local/bin/vim.
    vim --version should show Huge version and Compiled by jonathon@toolbx.

Enable Colors and Settings (System-wide)

To ensure that both your user and sudo (root) have the same experience, create your configuration files.

Create the Global Vim Configuration File
```bash
sudo vi /usr/local/share/vim/vimrc
```
add

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

Local userss configuration:
```bash
vim ~/.vimrc
```

Recommended baseline settings:
```bash
set nocompatible
syntax on
set termguicolors
set background=dark
colorscheme unokai
set number
set clipboard=unnamedplus
```

Use any theme from
```bash
ls -l  /usr/local/share/vim/colors/
```

🎨 Included Vim Colorschemes

These themes are installed system-wide in /usr/local/share/vim/colors/. To use one, type :colorscheme <name> inside Vim.
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

