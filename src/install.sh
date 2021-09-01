#!/bin/bash

# A script to automatically install qrdump
# Possibly this may only work on Debian / Ubuntu systems and the likes:
# as this relies on sudo, apt, and the etc/bash_completion.d .
# The installation will put everything in ~/bin (except the autocompletion function,
# that has to live in etc/bash_completion.d )

CWD="$(pwd)/"

echo "You are running the automatic installer for qrdump."
echo "This should work on Debian, Ubuntu and some related systems; to perform other"
echo "kind of installs, install by hand, or request a new feature on the project page!"
echo "This will perform a user installation only; if you want a system install, do this by"
echo "hand for now or request a new feature on the project page!"
echo "For more information, see the project page: https://github.com/jerabaul29/qrdump ."

echo "cd ~/bin ..."
mkdir -p ~/bin
cd ~/bin

echo "check for old version of qrdump-clone and clone if necessary..."
if [ -d "qrdump-clone" ]
then
  echo "previous version of qrdump-clone found, clean and re-install..."
  rm -rf qrdump-clone
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
QRDUMP_NEEDED_COMMANDS="ghostscript gs qrencode base64 zbarimg gzip gunzip split dd truncate convert img2pdf par2"
for QRDUMP_CRRT_PACKAGE in $QRDUMP_NEEDED_COMMANDS; do
    if [ -z $(which "$QRDUMP_CRRT_PACKAGE") ]; then
        echo "need to install a package providing ${QRDUMP_CRRT_PACKAGE} [requires sudo rights]..."
        if [ "${QRDUMP_CRRT_PACKAGE}" == "zbarimg" ]; then
            echo "install zbar-tools"
            sudo apt-get update
            sudo apt-get upgrade
            sudo apt-get install zbar-tools
        elif [ "${QRDUMP_CRRT_PACKAGE}" == "convert" ]; then
            echo "install zbar-tools"
            sudo apt-get update
            sudo apt-get upgrade
            sudo apt-get install imagemagick
        else
            echo "install ${QRDUMP_CRRT_PACKAGE}"
            sudo apt-get update
            sudo apt-get upgrade
            sudo apt-get install "${QRDUMP_CRRT_PACKAGE}" -y
        fi
    fi
done

echo "check if needed to update the rights for the convert command..."
convert -depth 8 -size 269x269 xc:white crrt_for_test_in.png
convert crrt_for_test_in.png crrt_for_test_in.pdf
convert -density 72 crrt_for_test_in.pdf crrt_for_test_out.png
if [ "$?" -ne "0" ]; then
    echo "need to set up execute rights for ImageMagick [this requires sudo]"
    DQT='"' 
    SRC="rights=${DQT}none${DQT} pattern=${DQT}PDF${DQT}"
    RPL="rights=${DQT}read\|write${DQT} pattern=${DQT}PDF${DQT}"
    sudo sed -i "s/$SRC/$RPL/" /etc/ImageMagick-6/policy.xml
fi
rm crrt_for_test_in.png
rm crrt_for_test_in.pdf
rm crrt_for_test_out.png

echo "check if need to install FreeMono fonts..."
if [ "$(fc-list | grep FreeMono | wc -l)" -lt 2 ]; then
    echo "need to install fonts..."
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get install fonts-freefont-otf
else
    echo "no extra fonts needed..."
fi

echo "run the tests to ensure installation validity..."
cd tests
bash run_all_tests.sh --quick-test
TESTS_RESULTS=$?

echo "taking you back to your initial location on the system..."
cd "${CWD}"

echo "If all tests passed, qrdump has been well installed! If not, ask for help on the project repo."
if [ "${TESTS_RESULT}"  -eq 0 ]; then
    echo "... done installing successfully."
    exit 0
else
    echo "... installation failed"
    exit 1
fi

