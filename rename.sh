#!/bin/bash
set -euo pipefail

# ---------------------------
# Usage Information
# ---------------------------
usage() {
  cat <<EOF
Usage: $0 [options] directory1 [directory2 ...]
Options:
  -r FILE    Replacement configuration file (default: replace.txt)
  -f         Flatten subdirectories (move files to the main directory)
  -d         Delete unwanted files (.nfo, .txt)
  -x         Enable debug output
  -h         Display this help message

The replacement file should contain lines like:
  "old phrase" "new phrase"
  "removeMe" ""
EOF
  exit 1
}

# ---------------------------
# Default Settings
# ---------------------------
REPLACE_FILE="replace.txt"
FLATTEN=false
DELETE_UNWANTED=false
DEBUG=false
UNWANTED_EXTS=(".nfo" ".txt")

# ---------------------------
# Option Parsing
# ---------------------------
while getopts "r:fdxh" opt; do
  case "$opt" in
    r) REPLACE_FILE="$OPTARG" ;;
    f) FLATTEN=true ;;
    d) DELETE_UNWANTED=true ;;
    x) DEBUG=true ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))
if [ "$#" -lt 1 ]; then
  usage
fi

# ---------------------------
# Debug Output Function
# ---------------------------
debug() {
  if [ "$DEBUG" = true ]; then
    echo "[DEBUG]" "$*" >&2
  fi
}

# ---------------------------
# Load Replacement Rules
# ---------------------------
# Two arrays: SEARCH and REPLACE store the rules.
declare -a SEARCH
declare -a REPLACE

if [ ! -f "$REPLACE_FILE" ]; then
  debug "Replacement file '$REPLACE_FILE' not found. No replacements will occur."
else
  while IFS= read -r line || [ -n "$line" ]; do
    # Remove leading/trailing whitespace and ignore comments/empty lines.
    line="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [[ -z "$line" || "$line" =~ ^# ]]; then
      continue
    fi
    # If line contains quoted strings.
    if [[ $line =~ \"([^\"]+)\"[[:space:]]+\"([^\"]*)\" ]]; then
      SEARCH+=("${BASH_REMATCH[1]}")
      REPLACE+=("${BASH_REMATCH[2]}")
      debug "Loaded rule: '${BASH_REMATCH[1]}' -> '${BASH_REMATCH[2]}'"
    else
      # Fallback: split on whitespace.
      read -r first rest <<< "$line"
      SEARCH+=("$first")
      REPLACE+=("$rest")
      debug "Loaded token rule: '$first' -> '$rest'"
    fi
  done < "$REPLACE_FILE"
fi

# ---------------------------
# Helper: Generate Unique Name
# ---------------------------
unique_name() {
  local dir="$1"
  local base="$2"
  local ext="$3"
  local new
  while : ; do
    new="${base}_$(date +%s%N | tail -c8)${ext}"
    if [ ! -e "$dir/$new" ]; then
      echo "$new"
      break
    fi
  done
}

# ---------------------------
# Process Filename Function
# ---------------------------
process_filename() {
  local filename="$1"
  local orig="$filename"
  debug "Processing filename: $orig"

  local base ext

  # Separate extension (preserve only the last period)
  if [[ "$filename" == *.* ]]; then
    base="${filename%.*}"
    ext=".${filename##*.}"
  else
    base="$filename"
    ext=""
  fi
  debug "Base: '$base' | Extension: '$ext'"

  # Convert dashes and underscores to spaces.
  base="${base//-/ }"
  base="${base//_/ }"
  debug "After converting '-' and '_' to spaces: '$base'"

  # Replace any remaining periods in base with spaces.
  base="${base//./ }"
  debug "After replacing periods in base: '$base'"

  # Apply search/replace rules.
  for i in "${!SEARCH[@]}"; do
    search="${SEARCH[$i]}"
    replace="${REPLACE[$i]}"
    # Using parameter substitution with sed for case-insensitive replacement.
    base="$(echo "$base" | sed -E "s/$(echo "$search" | sed 's/[][\/.^$*()]/\\&/g')/$replace/Ig")"
    debug "After replacing '$search' with '$replace': '$base'"
  done

  # Remove extra spaces.
  base="$(echo "$base" | sed 's/  */ /g' | sed 's/^ *//; s/ *$//')"
  debug "After removing extra spaces: '$base'"

  # Ensure base isn't empty.
  if [ -z "$base" ]; then
    base="file"
    debug "Base was empty, defaulting to 'file'"
  fi

  echo "${base}${ext}"
}

# ---------------------------
# Process a Single File
# ---------------------------
process_file() {
  local filepath="$1"
  local dir
  local file
  dir="$(dirname "$filepath")"
  file="$(basename "$filepath")"

  # If file is unwanted and DELETE_UNWANTED is true, delete and return.
  if [ "$DELETE_UNWANTED" = true ]; then
    for ext in "${UNWANTED_EXTS[@]}"; do
      if [[ "${file,,}" == *"${ext,,}" ]]; then
        debug "Deleting unwanted file: $filepath"
        rm -f "$filepath"
        return
      fi
    done
  fi

  local newfile
  newfile="$(process_filename "$file")"
  if [ "$file" = "$newfile" ]; then
    debug "No change for file: $file"
    return
  fi

  local newpath="$dir/$newfile"
  # Prevent overwrite by checking if target exists.
  if [ -e "$newpath" ]; then
    local base ext
    if [[ "$newfile" == *.* ]]; then
      base="${newfile%.*}"
      ext=".${newfile##*.}"
    else
      base="$newfile"
      ext=""
    fi
    newfile="$(unique_name "$dir" "$base" "$ext")"
    newpath="$dir/$newfile"
    debug "Filename collision. New filename: $newfile"
  fi

  debug "Renaming: '$filepath' -> '$newpath'"
  mv "$filepath" "$newpath"
}

# ---------------------------
# Process Directory
# ---------------------------
process_directory() {
  local root="$1"
  # Find all files recursively.
  find "$root" -type f | while IFS= read -r file; do
    process_file "$file"
  done

  # Flatten directory if requested.
  if [ "$FLATTEN" = true ]; then
    debug "Flattening directory: $root"
    find "$root" -mindepth 2 -type f | while IFS= read -r file; do
      local filename
      filename="$(basename "$file")"
      local target="$root/$filename"
      if [ -e "$target" ]; then
        local base ext
        if [[ "$filename" == *.* ]]; then
          base="${filename%.*}"
          ext=".${filename##*.}"
        else
          base="$filename"
          ext=""
        fi
        filename="$(unique_name "$root" "$base" "$ext")"
        target="$root/$filename"
        debug "Collision when flattening. New target: $target"
      fi
      debug "Moving '$file' to '$target'"
      mv "$file" "$target"
    done
    # Optionally remove empty subdirectories.
    find "$root" -type d -empty -delete
  fi
}

# ---------------------------
# Main Processing Loop
# ---------------------------
for directory in "$@"; do
  if [ ! -d "$directory" ]; then
    echo "Error: '$directory' is not a valid directory." >&2
    continue
  fi
  debug "Processing directory: $directory"
  process_directory "$directory"
done

debug "Processing complete."
