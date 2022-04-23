# docsplit
Split PDFs based on a regular expression.
It is part of my digitizing workflow for paper documents (which I will write later about).

The script will search for this expression: `(?<=[^0-9]00)[0-9]{3}(?=[^0-9])` on every page and will use the matching part as filename for the page the number was found on.
Pages without matches will be treated as belonging to the page with the last match.
The output will be scaled down to 200 dpi at the moment which gives around 200kB/page if you consider A4 pages.

Usage:
```bash
Usage: docsplit input.pdf output
Splits one large pdf into pieces.
'input.pdf' is the document to split.
'ouput' will produce splits like 'output.00538.pdf'.
The document number will be read from the files.
```

I used this project to learn a little bit about script testing.
If you are interested in this, check out the `dev` branch.