#!/usr/bin/env bash

# echo all commands before execution
#set -o verbose

usage() {
cat << EOF
Usage: $(basename $0) input.pdf output
Splits one large pdf into pieces.
'input.pdf' is the document to split.
'ouput' will produce splits like 'output.00538.pdf'.
The document number will be read from the files.
EOF
}

# Failure safety
# break on unset variables
set -o nounset 
# break on all errors
set -o errexit
# if error exit is probable use
# command || true

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

# Check that we have two parameters given
(( $# != 2 )) && usage && exit 0
# Check that the first parameter is a file
[[ ! -f $1 ]] && echo "The first parameter has to be a pdf that exists!" && usage && exit 1
# Check that we wouldn't overwrite anything
if compgen -G "$2"*.pdf > /dev/null; then
  echo "No files with a name like '$2*.pdf' may exsist - they could be overwritten!" && usage && exit 1
fi

# Alias ghostscript so we don't have to be so verbose
gs_command() {
  gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite -dCompatibilityLevel=1.3 -dPDFSETTINGS=/screen -dEmbedAllFonts=true -dSubsetFonts=true -dColorImageDownsampleType=/Bicubic -dColorImageResolution=200 -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=200 -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=200 $@
}

# Find pages in the pdf
# This constructs a python dict with page:found_number
pages=$(pdfgrep -no -P '(?<=[^0-9]00)[0-9]{3}(?=[^0-9])' "$1" | tr '\n' ', ' | sed 's/^/{/'; echo "}")
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
    last = f"-dLastPage={last}"
  print(f"gs_command -dFirstPage={first} {last} -sOutputFile={outdoc}.{number:05d}.pdf {indoc}")
page_dict = $pages
items = [(k,v) for k,v in page_dict.items()]
# This would be for using qpdf (but that would not make the pdfs smaller)
# for first, second in sliding_window(items,2):
#   qprint(first[0], second[0]-1, "$1", "$2", first[1])
# qprint(items[-1][0], "z", "$1", "$2", first[1])
for first, second in sliding_window(items,2):
  gsprint(first[0], second[0]-1, "$1", "$2", first[1])
gsprint(items[-1][0], "", "$1", "$2", first[1])
EOF
)
# This will execute the result from python line by line
# See https://unix.stackexchange.com/a/181581
echo "Processing PDFs..."
eval "$result"
echo "Finished!"