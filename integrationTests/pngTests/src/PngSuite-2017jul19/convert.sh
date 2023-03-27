#!/usr/bin/env sh

for filename in *.png; do
    convert $filename "${filename%%.*}".txt
done
