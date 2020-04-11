QRDUMP_NEEDED_COMMANDS="qrencode base64 zbarimg gzip gunzip split dd truncate convert img2pdf par2"

for QRDUMP_CRRT_PACKAGE in $QRDUMP_NEEDED_COMMANDS; do
    if [ -z $(which "$QRDUMP_CRRT_PACKAGE") ]; then
        echo "error: $QRDUMP_CRRT_PACKAGE command is not available, install needed package!"
        exit 1
    fi
done
