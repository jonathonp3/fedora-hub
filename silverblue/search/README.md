# 🔍 DocSearch Pro (search_docs.sh)

Overview

DocSearch Pro is a high-performance, unified search utility designed for Fedora Silverblue and other Linux workstations. While standard tools like grep struggle to read inside compressed Office formats, this script bridges the gap by scanning both plain text and document XML structures in a single pass.


📂 Supported File Formats

The script provides a unified search interface across a wide range of document types:

    Plain Text & Code: .txt, .md (Markdown), .html, .htm
    Modern Office: .docx (Microsoft Word) and .odt (LibreOffice/OpenDocument)
    Legacy Office: .doc (Microsoft Word 97-2003)
    Documents: .pdf (Portable Document Format)
    🛠️ System Mode (-s): Adds support for .log, .conf, .ini, .yaml, .sh, and files with no extension (e.g., /etc/fstab).

🛠️ Prerequisites & Dependencies

| Tool | Purpose | Fedora / Silverblue Command |
| :--- | :--- | :--- |
| **grep** | Core search engine (uses -E for regex) | Included |
| **find** | Navigates directory structures | Included |
| **unzip** | Reads XML from .docx and .odt files | `sudo dnf install unzip` |
| **antiword** | Converts legacy .doc files to text | `sudo dnf install antiword` |
| **pdftotext** | Converts .pdf files to searchable text | `sudo dnf install poppler-utils` |

    Note: On Fedora Silverblue, these tools are part of the base image. You can run DocSearchPro natively on the host without needing a Toolbox or layering additional packages.

🚀 Usage

Interactive Mode:
Simply run the script. It will default to your $HOME directory and prompt you for a search term.
```bash
docsearchpro
```
System Search (Btrfs subvolumes, logs, etc):
To search system configurations, use the -s (System) and -p (Partial match) flags.
```bash
sudo docsearchpro /etc -s -p "subvol"
```


🚀 Usage Instructions

Clone fedora-hub and make the script executable:
```bash
git clone https://github.com/your-username/fedora-hub.git
cd fedora-hub/silverblue/search
chmod +x DocSearchPro
```

Interactive Mode:
Simply run the script. It will automatically default to your $HOME directory and prompt you for a keyword.
```bash
./DocSearchPro
```

⌨️ Terminal Installation (Recommended)

To run DocSearchPro from any directory without typing the full path, install it to your local bin and create a lowercase alias:
bash

1. Copy to your binary folder

Local installation (no sudo):
```bash
mkdir -p ~/.local/bin
cp DocSearchPro ~/.local/bin/
```
Create a  symbolic link so as to allow launching script with the lower case name when using from the terminal
```bash
ln -s ~/.local/bin/DocSearchPro ~/.local/bin/docsearchpro
chmod +x ~/.local/bin/DocSearchPro
```
or

System wide installation (requires sudo):
```bash
sudo mkdir -p /usr/local/bin/
sudo cp ~/fedora-hub/silverblue/search/DocSearchPro /usr/local/bin/
```
Create a  symbolic link so as to allow launching script with the lower case name when using from the terminal
```bash
sudo ln -s /usr/local/bin/DocSearchPro /usr/local/bin/docsearchpro
```

2. Refresh your terminal
hash -r


3. Running a Search
Manual Directory & Keyword:
You can specify a directory such as Documents and a keyword via the command line to skip the prompts:
```bash
./DocSearchPro ~/Documents -k "kidneys"
```

Search Options

  -h, --help       Display this help message.
  -k, --keyword    Specify keyword (useful if keyword starts with -).
  -c, --case       Perform case-sensitive search.
  -p, --partial    Allow partial word matches (e.g., 'steve' matches 'steven').
  -s, --system     SYSTEM MODE: Search only configs, logs, scripts, and no-ext files.

Examples:
  docsearchpro 'steven'                   # Search home for 'steven'
  docsearchpro ~/Documents 'report'       # Search specific folder for 'report'
  docsearchpro -p 'trace elements'        # Partial match search in home
  sudo docsearchpro /etc -s -p subvol     # System search in /etc for 'subvol'
  docsearchpro /run/media/backup 'data'   # Search an external drive or mount

📂 Why this is better for Silverblue

    Symlink Aware: Uses $HOME to correctly navigate the /var/home structure.
    Native Performance: Runs as a native host script without the overhead of a container or Flatpak.
    Btrfs Optimized: Efficiently scans across Btrfs subvolumes on your physical disk


# 🖥️ Desktop Integration (GNOME Launcher) and Terminal

To launch DocSearch Pro directly from your GNOME Activities/Apps menu (like a native application) as well as from the terminal, follow these steps:
1. Move the Script to a Persistent Location

Clone fedora-hub if you have not already done so:
```bash
git clone https://github.com/your-username/fedora-hub.git
```

Place the script in /usr/local/bin/
```bash
sudo mkdir -p /usr/local/bin/
sudo cp ~/fedora-hub/silverblue/search/DocSearchPro /usr/local/bin/
```
Create a  symbolic link so as to allow launching script with the lower case name when using from the terminal
```bash
sudo ln -s /usr/local/bin/DocSearchPro /usr/local/bin/docsearchpro
```
Ensure the script is executable
```bash
chmod +x /usr/local/bin/docsearchpro
```
2. Create the Desktop Entry

Create a new file in the local applications folder:
```bash
vim ~/.local/share/applications/docsearchpro.desktop
```
Paste the following configuration:
```bash
[Desktop Entry]
Type=Application
Name=DocSearch Pro
Comment=Search text in Office and Text files
Exec=DocSearchPro
Icon=system-search
Terminal=true
Categories=Utility;TextTools;
Keywords=search;find;docs;office;
```
3. Update the Database

Tell GNOME to refresh the application list:
```bash
update-desktop-database ~/.local/share/applications/
```

To launch DocSearch Pro directly from the terminal:
```bash
DocSearchPro
```
or
```bash
docsearchpro
```
🚀 How it works

Easy Launch: Press the Super (Windows) key and type "DocSearch" to find and launch the tool.
Interactive: Because Terminal=true is set, the script will automatically open in Ptyxis (or your default terminal).
Persistent: The script includes a "Press any key to close" prompt at the end, ensuring the window stays open so you can read your search results.

How the search works in GNOME

    If you type "Doc", it will show up.
    If you type "Search", it will show up.
    If you type "Pro", it will show up.


Enjoy 🚀📂🛠️✨

