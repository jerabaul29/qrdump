if [[ "${DIGEST_IN}" = "${DIGEST_OUT}" ]]
then
    echo "RES success restoring"
else
    echo "RES non identical file"
    exit 1
fi

rm -rf dummy
cd ../tests/
