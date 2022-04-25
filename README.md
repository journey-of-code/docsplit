# docsplit
Split PDFs based on a regular expression.
It is part of my digitizing workflow for paper documents (which I will write later about).

The script will search for this expression: `(?<=[^0-9]00)[0-9]{3}(?=[^0-9])` on every page and will use the matching part as filename for the page the number was found on.
This would find five-digit numbers in the document that start with two leading zeros (but not numbers with more or less digits).
Pages without matches will be treated as belonging to the page with the last match.
The output will be scaled down to 200 dpi at the moment which gives around 200kB/page if you consider A4 pages.

Usage:
```bash
Usage: docsplit [options] input.pdf output
Splits one large pdf into pieces.

Options:
  --autoincrement=START
    Appends five-digit output numbers to the output files starting from START or 1 if START is not defined.
  --dividers
    Treat found (or given) page number as dividers and dont include them in the output.
  --help
    Output this text.
  --noop
    Simulate running the script but don't do anything.
  --pages=PAGES
    Prints the found pages in the given document if PAGES is not defined.
    If PAGES is defined, uses the given page numbers instead of searching them in the input pdf.
    The format is x1:n1,x2:n2,... where 'x' needs to be a number of a page in the document and 'n' the name of the resulting document postfix.
    'n' can also be empty.
  --regex=REGEX
    If present, replaces the default regex '(?<=[^0-9]00)[0-9]{3}(?=[^0-9])' with one of your own.
    The matching part will be post-fixed to the output name.
    Therefore it should be unique to the document, or --autoincrement should be used.
  --version
    Print the version of the script.

'input.pdf' is the document to split.
'ouput' will produce splits like 'output.00538.pdf'.
The document number will be read from the files by default.
```

# Examples
```bash
# This would:
# - apply the default regex to search for pages in the given file
# - output (echo) the commands that would be applied without noop
# Good for testing
docsplit.sh --noop "$DIR/data/Simple.pdf" "$TEST_DIR/file"
# Shows the found pages from the default regex.
# Good when the OCR failed for some pages.
# In that case you can use the output, insert or change the missed pages and use them instead.
docsplit.sh --pages "$DIR/data/Simple.pdf" "$TEST_DIR/file"
# Uses the given pages instead of searching for some
docsplit.sh --pages=1:385,4:386,6:387 "$DIR/data/Simple.pdf" "$TEST_DIR/file"
# Searches for the text "new document" in the source document and automatically count up from there.
# Think a punch that you can stamp on every new document that will split your OCR'd input file. 
docsplit.sh --regex="(?<=new page)" --autoinc=387 "$DIR/data/Simple.pdf" "$TEST_DIR/file"
```

## Devs
I used this project to learn a little bit about script testing.
If you are interested in this, check out the `dev` branch.