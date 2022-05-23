## Digitize your paperwork

Do you still receive letters in paper?
Do you need to archive them and search them, for example for doing taxes?
Then this small workflow might come in handy for you.
The basic idea is to wait a little while until you have a batch of letters and then digitize them.
The workflow worked for the last 10+ years for me and I finally found a complete open source way for my workflow.

### Basic idea

The basic idea is as follows:

1. Use an app to take photos of all pages of your documents
2. Let the app convert the photos into one searchable PDF
3. Post-process the PDF into PDFs for each document with automatic file naming
4. Archive the PDFs in a secure location (not part of this tutorial)

### Prerequisites:
* An Android phone (iPhone requires finding alternatives for the first step)
* A bash shell (Linux, MacOS and WSL on Windows should be fine)
* Rudimentary knowledge on how to interact with a shell (opening it, for example)
* Optional (but highly recommended): a black A2 piece of paper or area

### Installation

1. Install [DocScan](https://play.google.com/store/apps/details?id=at.ac.tuwien.caa.docscan) from the Google play store ([gh-link](https://github.com/TUWien/DocScan)).
2. On your computer, open a bash shell
3. Clone the [docsplit](https://github.com/journey-of-code/docsplit) tool: ```git clone https://github.com/journey-of-code/docsplit```
4. Optional: switch into the docsplit directory and make `docsplit.sh` available in your path
5. Run `docsplit.sh` - it will check for some dependencies and allows you to install them directly or at your will

### Workflow

1. Put your batch of papers neatly stacked onto a uniform (black) ground.
2. Open the DocScan app on your phone
3. Open the hamburger menu top left
4. Select `Documents`
5. Create a new document by pressing the bottom right `+`
6. You now automatically switch into the camera screen
7. Take photos of every page
> Note: for the splitting to work in the end, the first page of every document must be visible. Ideally, you have a counting stamp and the numbers can be used as filename. Still good is a stamp with some keyword. At least you should take a photo of a blank page before every new document so it is recognizable.
> Important: Make sure that `DocScan` correctly shows the cropping rectangle - you cannot crop otherwise. That is a shortcoming of the tool and unfortunately if one page is not correctly cropped, you have to retake that image and sort stuff later.
8. Switch to images
9. If all images have a proper crop rectangle, open the top right `⋮` menu and choose `Crop images`.
10. Open the top right `⋮` menu and choose `Save as PDF`.
11. Allow OCR when the app asks.
12. Wait for the OCR to finish (status is visible as notification).
13. Save the PDF.
> Note: The PDFs generated contain the unaltered images from your phone so the document is huge. That's why we definitely need to post-process on a computer.
14. Connect your phone to your computer and download the generated document.
> Note: DocScan places the file in `Documents/DocScan/`.
15. Call `docsplit` with the document.
> Note: Depending on the splitting you may now have to interact with the tool to provide the page numbers
16. Archive the resulting PDFs.
17. Done.

The resulting pages have around 200kB per A4 page (at least in my setup). This mostly depends on the dpi of the images that can be set for docsplit.
