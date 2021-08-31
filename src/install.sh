#!/bin/bash

# A script to automatically install qrdump
# The installation will put everything in ~/bin

CWD="$(pwd)/"

echo "You are running the automatic installer for qrdump."
echo "This should work on Ubuntu and systems with apt as package manager; to allow other"
echo "kind of installs, install by hand, or request a new feature on the project page!"
echo "This will perform a user installation only; if you want a system install, do this by"
echo "hand for now or request a new feature on the project page!"
echo "For more information, see the project page: https://github.com/jerabaul29/qrdump ."

echo "cd ~/bin ..."
mkdir -p ~/bin
cd ~/bin

echo "check for old version of qrdump-clone..."
if [ -d "qrdump-clone" ]
then
  echo "previous version of qrdump-clone found, clean and re-install..."
  rm -Rf qrdump-clone
fi

echo "clone the repository and move into it..."
git clone https://github.com/jerabaul29/qrdump qrdump-clone
cd qrdump-clone

echo "set up shortcut from ~/bin and make it executable..."
touch ~/bin/qrdump
echo "bash ~/bin/qrdump-clone/src/qrdump.sh" > ~/bin/qrdump
chmod +x ~/bin/qrdump

echo "set up autocompletion..."
echo "moving completion file to /etc/bash_completion.d/ [requires sudo rights]..."
sudo cp completion/qrdump_completion.sh /etc/bash_completion.d/.

echo "check if some extra packages are needed..."

QRDUMP_NEEDED_COMMANDS="qrencode base64 zbarimg gzip gunzip split dd truncate convert img2pdf par2"

for QRDUMP_CRRT_PACKAGE in $QRDUMP_NEEDED_COMMANDS; do
    if [ -z $(which "$QRDUMP_CRRT_PACKAGE") ]; then
        echo "need to install ${QRDUMP_CRRT_PACKAGE}; this will require sudo"
        sudo apt install "${QRDUMP_CRRT_PACKAGE}"
    fi
done

echo "run the tests..."
cd tests
bash run_all_tests.sh --quick-test

echo "qrdump has been well installed!"

echo "taking you back to your initial location..."
cd "${CWD}"

