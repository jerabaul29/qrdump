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

Quick example data file to A4 pdf and back: qrdump.sh has been copied locally to do this test):

```
✔ jrlab-ThinkPad-T490:~/Desktop/Git/qrdump/src> head -c 4096 </dev/urandom > dummy.dat
✔-1 jrlab-ThinkPad-T490:~/Desktop/Git/qrdump/src> ./qrdump.sh --create-A4 --base64 --output ./pdf_dump.pdf --input dummy.dat 
✔-127 jrlab-ThinkPad-T490:~/Desktop/Git/qrdump/src> sha1sum dummy.dat 
58428a3b55a3f3067a2804aff4728f6f9d29b1ba  dummy.dat
✔ jrlab-ThinkPad-T490:~/Desktop/Git/qrdump/src> rm dummy.dat 
✔ jrlab-ThinkPad-T490:~/Desktop/Git/qrdump/src> ./qrdump.sh --base64 --read-A4 --input pdf_dump.pdf --output ./
✔ jrlab-ThinkPad-T490:~/Desktop/Git/qrdump/src> sha1sum dummy.dat 
58428a3b55a3f3067a2804aff4728f6f9d29b1ba  dummy.dat
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

- develop unit testing
- setup packaging
- extend functionality following the TODOs in the source
- pdf metadata should include relevant information
- refactor inner code in particular paths etc and how they are given from one function to the other (make to arg instead of global variables)
- clean the verbose outputs etc

