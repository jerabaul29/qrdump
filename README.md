# qrdump

**qrdump**: a tool for dumping data into a series of qr-codes for long-time archiving.

:warning: :construction: **this is a very recent repo very much under construction; consider waiting a bit before starting to use the code here; contributions / feedback / code reviews welcome though** :construction: :warning:

The platformed aimed for is linux. The code is a set of bash scripts leveraging standard linux packages.

The aim of this repository is to provide a default-solution for dumping data into a series of QR-codes together with metadata, with the aim of long-term archiving. Examples of applications include dumping GPG private keys for long-time storage, dumping encrypted pass password manager content, or simply any long time archiving of numerical data.

The package is a set of bash scripts and functions to make it easy to:

- dump data as a set of several QR-format, with extensive meta-data
- layout the QR-codes on a standard A4 pages in a standardised way
- recover the QR-codes and put their contents automatically together to re-create the initial data.

# use

See the *src/test_script_XX.sh* examples for details.

Quick example data file to A4 pdf:

```bash ./qrdump.sh --create-A4 --base64 -b -v --output ./dummy/generated_pdf/my_pdf.pdf ./dummy/dummy_file.dat
```

Quick example A4 pdf to data file:

```bash ./qrdump.sh --recover --base64 -b -v --output ./dummy/restored_result/ ./dummy/generated_pdf/my_pdf.pdf
```

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

- make a full (even if limited) working example
- develop unit testing
- setup packaging
- extend functionality following the TODOs in the source

