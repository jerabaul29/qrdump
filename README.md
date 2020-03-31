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

The pdf_dump.pdf is easily printable (and then scannable). A bit of metadata (page number) is present by default. Additional metadata can be added either on first page, or on the top of each page (TODO: implement). For example, the pdf output (shown fully with pages side-by-side) for 4096 bytes look like:

![Illustration of pdf output (here dump of 4096 bytes)](doc/illustration_pdf_dump/illustration.png?raw=true)

# Installation

- clone the repo
- use the /src/qrdump script as shown in the example
- for easy use, consider setting up a bash alias:

```
alias qrdump='bash ~/Desktop/Git/qrdump/src/qrdump.sh'
```

# tests

Execute /tests/run_all_tests.sh to run all tests.
