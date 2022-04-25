#!/usr/bin/env bash

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
  --pages_please
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
  executable=$(basename $0)
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
  TEMP=`getopt -o h \
               --long help,noop,pages_please,regex:,version \
               -n 'docsplit.sh' -- "$@"`
  # Defaults
  PRINT_HELP=""
  PRINT_VERSION=""
  NOOP=""
  PAGES=""
  REGEX='(?<=[^0-9]00)[0-9]{3}(?=[^0-9])'
  # Break on errors and report correct usage.
  if [ $? != 0 ] ; then echo "ERROR: Came accross a wrong option. Terminating..." >&2; usage; exit 1 ; fi
  # Note the quotes around `$TEMP': they are essential!
  eval set -- "$TEMP"
  while true; do
    case "$1" in
      -h | --help ) PRINT_HELP=true; shift ;;
      --noop ) NOOP=true; shift ;;
      --pages_please ) PAGES=true; shift ;;
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
(( $# != 2 )) && usage && exit 1
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
# This constructs a python dict with page:found_number
# pages=$(pdfgrep -no -P "$(printf '[%q]' $REGEX)" "$1" | tr '\n' ', ' | sed 's/^/{/'; echo "}") || true
pages=$(pdfgrep -no -P "$REGEX" "$1" | tr '\n' ', ' | sed 's/^/{/'; echo "}") || true
[[ $PAGES ]] && echo "$pages" && exit 0
# Create a command line for ghostscript
result=$(python3 <<EOF
def sliding_window(elements, window_size):
  if len(elements) <= window_size:
    return elements
  for i in range(len(elements)- window_size + 1):
    yield elements[i:i+window_size]
def qprint(first, last, indoc, outdoc, number):
  print(f"qpdf {indoc} --pages {indoc} {first}-{last} -- {outdoc}.{number:05d}.pdf")
def gsprint(first, last, indoc, outdoc, number):
  if last:
    last = f" -dLastPage={last}"
  print(f"gs_command -dFirstPage={first}{last} -sOutputFile={outdoc}.{number:05d}.pdf {indoc}")
page_dict = $pages
items = [(k,v) for k,v in page_dict.items()]
for first, second in sliding_window(items,2):
  gsprint(first[0], second[0]-1, "$1", "$2", first[1])
gsprint(items[-1][0], "", "$1", "$2", items[-1][1])
EOF
)
# This will execute the result from python line by line
# See https://unix.stackexchange.com/a/181581
if [[ $NOOP ]]; then
  echo "$result"
else
  echo "Processing PDFs..."
  eval "$result"
  echo "Finished!"
fi
