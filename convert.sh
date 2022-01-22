#!/usr/bin/env bash

for file in **/*.org; do
  echo $file
  name=$(echo "$file" | cut -f 1 -d '.')
  pandoc -s "$file" -o "$name".pdf --pdf-engine=lualatex
  pandoc -s "$file" -o "$name".md
done
