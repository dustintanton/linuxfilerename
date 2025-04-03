# linuxfilerename
Linux Mass Rename Program

Robust File Renaming Script for Linux

This Bash script provides a powerful file renaming solution for Linux, offering functionality comparable to advanced PowerShell scripts. It processes filenames based on configurable search/replacement rules, cleans up unwanted characters, and supports operations on multiple directories. It also offers optional features such as flattening directory structures and deleting unwanted file types.
Features

    Word/Phrase Removal:
    Remove specific words or phrases from filenames using a configurable replace.txt file.

    Search and Replace Functionality:
    Replace occurrences of a given string with another string across filenames.

    Multiple Directories Support:
    Process one or more directories recursively.

    Character Conversion:
    Converts dashes (-) and underscores (_) to spaces.

    Period Handling:
    Converts periods in the base filename to spaces while preserving the final period for the extension.

    File Structure Management:
    Optionally flatten subdirectories by moving files to the main directory or delete unwanted files (e.g., .nfo, .txt).

    Prevent Overwrites:
    Detects filename collisions and appends a unique identifier if needed.

    Debugging and Verification:
    Provides detailed debug output for verifying that the replacement rules are correctly loaded and applied.

Requirements

    A Linux-based operating system.

    Bash shell (v4 or later is recommended).

    Standard Linux utilities: sed, mv, find, etc.

    Optional: dos2unix for converting Windows line endings (if necessary).

Installation

    Clone or download this repository.

    Ensure the script has execute permissions:

    chmod +x rename2.sh

Configuration

The script uses a configuration file named replace.txt (by default) to determine which words or phrases to replace or remove. Each line in the file can have one of the following formats:

    Replacement Rule:
    "search phrase" "replacement phrase"

    Removal Rule:
    "wordOrPhraseToRemove" ""

For example:

"WEBRip" ""
"(" ""
")" ""
"YTS MX" ""

You can also add additional entries as needed.
Usage

Run the script from the command line with the desired options:

./rename2.sh [options] directory1 [directory2 ...]

Options

    -r FILE
    Specify a replacement configuration file (default: replace.txt).

    -f
    Flatten subdirectories by moving files into the main directory.

    -d
    Delete unwanted files (by default, files with .nfo and .txt extensions).

    -x
    Enable debug output for detailed processing information.

    -h
    Display usage/help message.

Example

To process the /downloads/Movies directory with debug output enabled:

./rename2.sh -x /downloads/Movies

To process multiple directories, flatten the directory structure, and delete unwanted files:

./rename2.sh -x -f -d /downloads/Movies /downloads/Anime

Debug Output

When run with the -x option, the script prints debug messages (to standard error) that show:

    Loaded replacement rules from replace.txt.

    Step-by-step filename processing.

    File renaming operations and directory flattening details.

Troubleshooting

    DOS/Windows Line Endings:
    If you see errors like cannot execute: required file not found, ensure your script has Unix line endings:

    dos2unix rename2.sh

    Special Characters in Rules:
    If you encounter issues with special regex characters (e.g., (, )), ensure they are escaped by adding them to your replace.txt or modify the script to automatically remove these characters.

Contributing

Contributions, suggestions, and improvements are welcome. Please open an issue or submit a pull request with your changes.
License

This project is open source and available under the MIT License.
