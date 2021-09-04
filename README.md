# qrdump

**qrdump**: a tool for long-time paper archiving of data within multiple qr-codes.

The platformed aimed for is linux. The code is a set of bash scripts leveraging standard linux packages.

The aim of this repository is to provide a default-solution for dumping a file into a series of QR-codes together with metadata and putting these together into a series of A4 pdf pages, with the aim of long-term archiving on printed paper. Examples of applications include dumping GPG private keys for long-time storage, dumping encrypted pass password manager content, or simply any long time archiving of any data.

The package is a set of bash scripts and functions to make it easy to:

- Dump data as a set of several QR-codes, with extensive meta-data, and layout as a printable pdf.
- Recover the QR-codes from the pdf dump, and assemble them together to re-create the initial data.

Currently the size of the QR-codes and the layout on the A4 pdf pages are hard coded and cannot be changed easily (this may be improved with a future update). The 'small squares' inside the QR-codes have a side of 3x3 dots at 72dpi, which should be quite conservative for use with modern printers and scanners.

# Use

Quick example data file to A4 pdf and back:

```
bash-4.4$ FOLDER_TESTS=$(mktemp -d)
bash-4.4$ cd $FOLDER_TESTS/
bash-4.4$ head -c 4096 </dev/urandom > dummy.dat # create a random file, 4096 bytes
bash-4.4$ sha256sum dummy.dat 
02f2c6dd472f43e9187043271257c1bf87a2f43b771d843e45b201892d9e7b84  dummy.dat
bash-4.4$ bash ~/Desktop/Git/qrdump/src/qrdump.sh --create-A4 --base64 --safe-mode --output ./pdf_dump.pdf --input dummy.dat --metadata "a user-define message" # crete a printable qr-codes pdf of the file
SAFE to use: success restoring check
bash-4.4$ rm dummy.dat # the file is removed, so from now on only way to get it back is to restore from the pdf
bash-4.4$ bash ~/Desktop/Git/qrdump/src/qrdump.sh --base64 --read-A4 --input pdf_dump.pdf --output ./ # restore
bash-4.4$ sha256sum dummy.dat # the digest should be the same as the initial one to confirm good restore
02f2c6dd472f43e9187043271257c1bf87a2f43b771d843e45b201892d9e7b84  dummy.dat
```

The pdf_dump.pdf is easily printable (and then scannable back in many years). A bit of metadata (page number) is present by default. Additional metadata can be added either on first page, or on the top of each page (NOTE: work in progress, TODO: implement). For example, the pdf output (shown fully with pages side-by-side) for the 4096 bytes example looks like:

![Illustration of pdf output (here dump of 4096 bytes)](doc/illustration_pdf_dump/illustration_2.png?raw=true)

# Installation

## Installation with **install.sh** script

We provide an **install.sh** script. This script is focused on Debian, Ubuntu, and derived systems (for example you will need to have apt-get on your system for the script to work). Some of the steps may require sudo.

To install with a single command (you may be prompted for your sudo password in the process):

```
wget https://raw.githubusercontent.com/jerabaul29/qrdump/master/src/install.sh && bash install.sh
```

## Installation by hand

To install by hand on any linux distribution (you can still see the **src/install.sh** script for an overview of the steps to perform):

- clone the repo

- use the ```/src/qrdump script``` as shown in the example

- install the packages necessary (TODO: requirements; for now, your bash will complain when commands are not available). These should be in format command: package (note: requirements is work under progress, list may not be exhaustive, open issues if stuff not working)

```
qrencode: qrencode
base64: coreutils
zbarimg: install zbar-tools
gzip: gzip
gunzip: gzip
split: coreutils
dd: coreutils
truncate: coreutils
convert: imagemagick
img2pdf: img2pdf
par2: par2
```

- for autocomplete, source ```completion/qrdump_completion.sh```

- for easy use, consider setting up a bashrc sourcing and alias (adapt the path to the package, this is for my machine where it is cloned on ~Desktop/Git/qrdump/):

```
source ~/Desktop/Git/qrdump/completion/qrdump_completion.sh
alias qrdump='bash ~/Desktop/Git/qrdump/src/qrdump.sh'
```

# Tests

Execute ```/tests/run_all_tests.sh``` to run all tests.

All tests passing on Ubuntu 18.04 with relevant pacakges installed.

# Notes

- This works for quite large files. The following example shows that dumping and restoring a 100K file is fine. Takes around half a minute on my machine. The pdf is just 55 pages long.

```
bash-4.4$ head -c 100k </dev/urandom > dummy.dat
bash-4.4$ ls -lh
total 100K
-rw-r--r-- 1 jrlab jrlab 100K mars  31 17:58 dummy.dat
bash-4.4$ bash ~/Desktop/Git/qrdump/src/qrdump.sh --create-A4 --base64 --safe-mode --output ./pdf_dump.pdf --input dummy.dat
SAFE to use: success restoring check
```

- Yhe metadata can be quite long, and it will be if needed cut, and wrapped, as needed, but the dump will not fail / be corrupted:

```
bash ~/Desktop/Git/qrdump/src/qrdump.sh --create-A4 --base64 --safe-mode --output ./pdf_dump.pdf --input dummy.dat --metadata "this is the metadata message aaaa bbbbb ccccc ddddd eeeee fffff ggggg qqqqq ggkgewg gnwpgwqgq. it can be quite long, and will be cut / wrapped as needed. is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
```

- Regarding encoding: ```zbarimg``` used to not support extracting binary data. This was added only recently to the tool, see: https://stackoverflow.com/questions/60506222/encode-decode-binary-data-in-a-qr-code-using-qrencode-and-zbarimg-in-bash . This is now supported in the ```zbarimg``` that ships with Ubuntu 21.04 and higher, but lower versions (such as 20.04LTS) will only work using the ```--base64``` flag. The tool will automatically warn if you try to use binary encoding while your libraries are only compatible with base64.

- The tool is still early in its life, but I have been using it with success myself. If you use the ```--safe-mode``` and ```--parchive``` flags, qrdump will both 1) check that the encoded pdf can be correctly decoded, 2) dump in addition to the data all the par2 data needed to robustify the dump. Still, the tool comes with **NO WARRANTEE WHATSOEVER** from my side.

