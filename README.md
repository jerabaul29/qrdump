# qrdump

**qrdump**: a tool for dumping data into a series of qr-codes for long-time archiving.

The platformed aimed for is linux. The code is a set of bash scripts leveraging standard linux packages.

The aim of this repository is to provide a default-solution for dumping data into a series of QR-codes together with metadata, with the aim of long-term archiving. Examples of applications include dumping GPG private keys for long-time storage, dumping encrypted pass password manager content, or simply any long time archiving of numerical data.

The package is a set of bash scripts and functions to make it easy to:

- dump data as a set of several QR-format, with extensive meta-data
- layout the QR-codes on a standard A4 pages in a standardised way
- recover the QR-codes and put their contents automatically together to re-create the initial data.

# status

Under heavy development, not yet ready for use - come back in a few weeks.

# installation

The content of the **src** folder is simply a set of bash scripts

# TODO

Extensive list of TODOS at the moment:

- make a full (even if limited) working example
- develop unit testing
- setup packaging
- extend functionality following the TODOs in the source

