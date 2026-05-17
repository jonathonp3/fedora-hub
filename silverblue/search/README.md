🔍 DocSearch Pro (search_docs.sh)
Overview

DocSearch Pro is a high-performance, unified search utility designed for Fedora Silverblue and other Linux workstations. While standard tools like grep struggle to read inside compressed Office formats, this script bridges the gap by scanning both plain text and document XML structures in a single pass.
Purpose

The script allows you to search for specific text strings or keywords across:

    Plain Text: .txt
    Modern Office: .docx (Microsoft Word) and .odt (LibreOffice/OpenDocument)
    Legacy Office: .doc (Microsoft Word 97-2003)

🛠️ Prerequisites & Dependencies

Fedora Silverblue includes these tools by default. If you are running this on a minimal install of fedora install the following if not already installed:

Tool	Purpose	Fedora/Silverblue Command

grep  - Core search engine (uses -E for extended regex)	Included in most linux distrobutions
find  - Navigates directory structures	Included in most linux distrobutions
unzip - Extracts and reads XML from .docx and .odt (included in 
```bash
sudo dnf install unzip
```

antiword - Converts binary .doc files to searchable text
```bash
sudo dnf install antiword
```

🚀 Usage Instructions
1. Installation

Clone fedora-hub and make the script executable:
```bash
git clone https://github.com/your-username/fedora-hub.git
cd fedora-hub/silverblue/search
chmod +x search_docs.sh
```

2. Running a Search

Interactive Mode:
Simply run the script. It will automatically default to your $HOME directory and prompt you for a keyword.
```bash
./search_docs.sh
```

Manual Directory & Keyword:
You can specify a directory and a keyword via the command line to skip the prompts:
bash

./search_docs.sh /path/to/documents -k "kidneys"

3. Search Options

    -k [keyword]: Sets the search term via command line.
    -p: Partial match. Use this if you want "kidney" to match "kidneys" or "kidney-stone."
    -c: Case-sensitive. Use this for strict matching (e.g., "Steven" vs "steven").

📂 Why this is better for Silverblue

    Symlink Aware: Uses $HOME to correctly navigate the /var/home structure.
    Native Performance: Runs as a native host script without the overhead of a container or Flatpak.
    Btrfs Optimized: Efficiently scans across Btrfs subvolumes on your physical dis

Enjoy 🚀📂🛠️✨

