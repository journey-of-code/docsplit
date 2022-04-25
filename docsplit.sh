#!/usr/bin/env bash

executable=$(basename $0)
VERSION="0.1"
AUTHOR="Pascal Bertram"

usage() {
cat << EOF
Usage: $(basename $0) [options] input.pdf output
Splits one large pdf into pieces.

Options:
  --help
    Output this text.
  --noop
    Simulate running the script but don't do anything.
  --pages
    Find the pages in the given document.
  --version
    Print the version of the script.
  --regex
    Specify an own regex that will be used to extract the file numbers/names.

'input.pdf' is the document to split.
'ouput' will produce splits like 'output.00538.pdf'.
The document number will be read from the files.

Author: $AUTHOR
Version: $VERSION
EOF
}

version() {
  echo "${executable%\.sh} $VERSION"
}

# Failure safety
# break on unset variables
set -o nounset 
# break on all errors
set -o errexit
# if error exit is probable use
# command || true
# echo all commands before execution
#set -o verbose

# Check that all packages are installed that we need
needed_packages=( ghostscript pdfgrep python3 )
install_help()
{
  echo "One of these packages is missing: ${needed_packages[@]}"
  ## Prompt the user
  read -p "Do you want to install missing libraries? [Y/n]: " answer
  ## Set the default value if no answer was given
  answer=${answer:-"Y"}
  ## If the answer matches y or Y, install
  [[ $answer =~ [Yy] ]] && sudo apt-get install "${needed_packages[@]}" || echo "Packages missing. Aborting" && exit 1
}
## Run the run_install function if any of the libraries are missing
dpkg -s "${needed_packages[@]}" >/dev/null 2>&1 || install_help
# Parse parameters
# See http://stackoverflow.com/questions/402377/using-getopts-in-bash-shell-script-to-get-long-and-short-command-line-options
# -o list of all single letter parameters (trailing ':' means it needs to have a value)
# --long list of all long options (trailing ':' means it needs to have a value)
# -n name of program to report
{
  # Defaults
  PRINT_HELP=""
  PRINT_VERSION=""
  NOOP=""
  PAGES=""
  PRINTPAGES=""
  PARSEFAIL=""
  REGEX='(?<=[^0-9]00)[0-9]{3}(?=[^0-9])'
  # Read options
  TEMP=$(getopt -o h \
               --long help,noop,pages::,regex:,version \
               -n "$executable" -- "$@") || PARSEFAIL=true
  # Break on errors and report correct usage.
  [[ $PARSEFAIL ]] && usage && exit 1
  # Note the quotes around `$TEMP': they are essential!
  eval set -- "$TEMP"
  while true; do
    case "$1" in
      -h | --help ) PRINT_HELP=true; shift ;;
      --noop ) NOOP=true; shift ;;
      --pages )
        case "$2" in
          "") PRINTPAGES=true; shift 2 ;;
          *) PAGES=$2 ; shift 2 ;;
        esac ;;
      --version ) PRINT_VERSION=true; shift ;;
      --regex ) REGEX="$2"; shift 2 ;;
      -- ) shift; break ;;
      * ) break ;;
    esac
  done
}
# Print help if wanted and exit.
[[ $PRINT_VERSION ]] && version && exit 0
[[ $PRINT_HELP ]] && usage && exit 0

# Checking assumptions
# Check that we have two parameters given
(( $# != 2 )) && echo "Expecting two nameless parameters. Got $#." && usage && exit 1
# Check that the first parameter is a file
[[ ! -f $1 ]] && echo "The first parameter has to be a pdf that exists!" && usage && exit 1
# Check that we wouldn't overwrite anything
out_files=$(compgen -G "$2*.pdf") || true
if [ -n "$out_files" ] >/dev/null ; then
 echo "No files with a name like '$2*.pdf' may exist - they could be overwritten!"
 echo "Found the following file(s):"
 echo "$out_files"
 usage && exit 1
fi

# Alias ghostscript so we don't have to be so verbose
gs_command() {
  gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite -dCompatibilityLevel=1.3 -dPDFSETTINGS=/screen -dEmbedAllFonts=true -dSubsetFonts=true -dColorImageDownsampleType=/Bicubic -dColorImageResolution=200 -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=200 -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=200 $@
}

# Find pages in the pdf
# Results in a list with page:found_number,...
[[ $PAGES ]] || PAGES=$(pdfgrep -no -P "$REGEX" "$1" | tr '\n' ', ' | sed 's/,$//') || true
[[ $PRINTPAGES ]] && echo "$PAGES" && exit 0
# Create a command line for ghostscript
result=$(python3 <<EOF
pages = "$PAGES"

inpages, outfiles = [], []
result = ""
def gsprint(first, last, indoc, outdoc, number):
  global result, inpages, outfiles
  if first in inpages:
    print(f"page '{first}' would result in two different output files.")
    exit(1)
  inpages.append(first)
  if last:
    last = f" -dLastPage={last}"
  if number.isdigit(): number = f"{int(number):05d}"
  outfile=f"{outdoc}.{number}.pdf"
  result += f"gs_command -dFirstPage={first}{last} -sOutputFile={outfile} {indoc}\n"
  if outfile in outfiles:
    print(f"the file '{outfile}' (from page {first}) would be overwritten with the current page names.")
    exit(1)
  outfiles.append(outfile)

def sliding_window(elements, window_size):
  if len(elements) <= window_size:
    return elements
  for i in range(len(elements)- window_size + 1):
    yield elements[i:i+window_size]

items = [(int(e[0]),e[1]) for e in [e.split(":") for e in pages.split(",") if e]]
for first, second in sliding_window(items,2):
  gsprint(first[0], second[0]-1, "$1", "$2", first[1])
gsprint(items[-1][0], "", "$1", "$2", items[-1][1])
print(result)
EOF
) || PARSEFAIL=true
[[ $PARSEFAIL ]] && echo "With the pages: '$PAGES', $result" && exit 1
# This will execute the result from python line by line
# See https://unix.stackexchange.com/a/181581
if [[ $NOOP ]]; then
  echo "$result"
else
  echo "Processing PDFs..."
  eval "$result"
  echo "Finished!"
fi
