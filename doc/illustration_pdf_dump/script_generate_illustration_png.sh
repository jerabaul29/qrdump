#!/bin/bash

# make a small illustration of how the pdf output of 4096 bytes looks like

convert -density 72 "pdf_dump.pdf" ./extracted_A4_page_%04d.png &> /dev/null

CRRT_PNG_Y_SIZE=$(identify "extracted_A4_page_0000.png" | awk '{print $3;}' | cut -d'x' -f2)
convert -size ${10}x${CRRT_PNG_Y_SIZE} xc:black ./separator.png

convert separator.png extracted_A4_page_0000\.png separator.png extracted_A4_page_0001.png separator.png extracted_A4_page_0002.png separator.png extracted_A4_page_0003.png separator.png +append tmp.png

CRRT_PNG_X_SIZE=$(identify "tmp.png" | awk '{print $3;}' | cut -d'x' -f1)
convert -size ${CRRT_PNG_X_SIZE}x${10} xc:black ./vseparator.png

convert vseparator.png tmp.png vseparator.png -append illustration.png
