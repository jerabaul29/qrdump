# qrdump

**qrdump**: a tool for long-time paper archiving of data within multiple qr-codes.

The platformed aimed for is linux. The code is a set of bash scripts leveraging standard linux packages.

The aim of this repository is to provide a default-solution for dumping a file into a series of QR-codes together with metadata and putting these together into a series of A4 pdf pages, with the aim of long-term archiving on printed paper. Examples of applications include dumping GPG private keys for long-time storage, dumping encrypted pass password manager content, or simply any long time archiving of any data.

The package is a set of bash scripts and functions to make it easy to:

- Dump data as a set of several QR-codes, with extensive meta-data, and layout as a printable pdf.
- Recover the QR-codes from the pdf dump, and assemble them together to re-create the initial data.

# Use

Quick example data file to A4 pdf and back:

```
bash-4.4$ FOLDER_TESTS=$(mktemp -d)
bash-4.4$ cd $FOLDER_TESTS/
bash-4.4$ head -c 4096 </dev/urandom > dummy.dat # create a random file, 4096 bytes
bash-4.4$ sha256sum dummy.dat 
02f2c6dd472f43e9187043271257c1bf87a2f43b771d843e45b201892d9e7b84  dummy.dat
bash-4.4$ bash ~/Desktop/Git/qrdump/src/qrdump.sh --create-A4 --base64 --safe-mode --output ./pdf_dump.pdf --input dummy.dat # crete a printable qr-codes pdf of the file
SAFE to use: success restoring check
bash-4.4$ rm dummy.dat # the file is removed, so from now on only way to get it back is to restore from the pdf
bash-4.4$ bash ~/Desktop/Git/qrdump/src/qrdump.sh --base64 --read-A4 --input pdf_dump.pdf --output ./ # restore
bash-4.4$ sha256sum dummy.dat # the digest should be the same as the initial one to confirm good restore
02f2c6dd472f43e9187043271257c1bf87a2f43b771d843e45b201892d9e7b84  dummy.dat
```

The pdf_dump.pdf is easily printable (and then scannable back in many years). A bit of metadata (page number) is present by default. Additional metadata can be added either on first page, or on the top of each page (NOTE: work in progress, TODO: implement). For example, the pdf output (shown fully with pages side-by-side) for the 4096 bytes example looks like:

![Illustration of pdf output (here dump of 4096 bytes)](doc/illustration_pdf_dump/illustration.png?raw=true)

# Installation

- clone the repo
- use the ```/src/qrdump script``` as shown in the example
- for easy use, consider setting up a bashrc alias:

```
alias qrdump='bash ~/Desktop/Git/qrdump/src/qrdump.sh'
```

# Tests

Execute ```/tests/run_all_tests.sh``` to run all tests.

All tests passing on Ubuntu 18.04 with relevant pacakges installed.

# Notes

:warning: :construction: **this is a very recent tool still under construction; consider waiting a bit before starting to use the code here for production; contributions / feedback / code reviews welcome though** :construction: :warning:

