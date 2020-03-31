# qrdump

**qrdump**: a tool for dumping data into a series of qr-codes for long-time archiving.

:warning: :construction: **this is a very recent repo very much under construction; consider waiting a bit before starting to use the code here; contributions / feedback / code reviews welcome though** :construction: :warning:

The platformed aimed for is linux. The code is a set of bash scripts leveraging standard linux packages.

The aim of this repository is to provide a default-solution for dumping data into a series of QR-codes together with metadata, with the aim of long-term archiving. Examples of applications include dumping GPG private keys for long-time storage, dumping encrypted pass password manager content, or simply any long time archiving of numerical data.

The package is a set of bash scripts and functions to make it easy to:

- dump data as a set of several QR-codes, with extensive meta-data, and layout as a printable pdf
- recover the QR-codes from dump pdf, and assemble them together to re-create the initial data.

# use

Quick example data file to A4 pdf and back:

```
bash-4.4$ FOLDER_TESTS=$(mktemp -d)
bash-4.4$ cd $FOLDER_TESTS/
bash-4.4$ head -c 4096 </dev/urandom > dummy.dat
bash-4.4$ sha256sum dummy.dat 
02f2c6dd472f43e9187043271257c1bf87a2f43b771d843e45b201892d9e7b84  dummy.dat
bash-4.4$ bash ~/Desktop/Git/qrdump/src/qrdump.sh --create-A4 --base64 --safe-mode --output ./pdf_dump.pdf --input dummy.dat
SAFE to use: success restoring check
bash-4.4$ rm dummy.dat 
bash-4.4$ ls
pdf_dump.pdf
bash-4.4$ bash ~/Desktop/Git/qrdump/src/qrdump.sh --base64 --read-A4 --input pdf_dump.pdf --output ./
bash-4.4$ sha256sum dummy.dat 
02f2c6dd472f43e9187043271257c1bf87a2f43b771d843e45b201892d9e7b84  dummy.dat
```

The pdf_dump.pdf is easily printable (and then scannable). For example, the pdf output (shown fully with pages side-by-side) for 4096 bytes look like:

![Illustration of pdf output (here dump of 4096 bytes)](doc/illustration_pdf_dump/illustration.png?raw=true)

# status

**NOTE** things are *working* when a working implementation, possibly with flaws, is available. Things are *cleaning* when the cleaning / refactoring is starting to be done and code starts to look nice. Things are *done* when satisfactory cleaning has taken place and production quality is met. See the TODOs / FIXMEs in the code for suggestion of how to improve / fix.

## encoding / decoding
- generating a list of qr dumps from arbitrary data: working.
- decoding a list of qr dumps to arbitraty data: working.

## layout / extraction
- putting qr codes from the encoding in a series of A4 pages: working.
- extract the qr codes from layout in a series of A4 pages: working.

## complete workflow
- file to A4: working
- A4 to file: working

## code cleaning
- avoid polluting folders with tmp files (ie move temporaty stuff to tmp files): under progress
- stabilize APIs: working

# installation

The content of the **src** folder is simply a set of bash scripts

# TODO

Extensive list of TODOS at the moment:

- develop unit testing
- setup packaging
- extend functionality following the TODOs in the source
- pdf metadata should include relevant information
- refactor inner code in particular paths etc and how they are given from one function to the other (make to arg instead of global variables)
- clean the verbose outputs etc

