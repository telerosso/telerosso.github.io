#!/bin/bash
showdown="node_modules/.bin/showdown"

rm -Rf docs
mkdir docs

for src in $(find ./src -name '*.jpg' -or -name '*.png'); do
  out="$(echo "$src" | sed -r 's/^.\/src\//.\/docs\//')"
  mkdir -p $(dirname $out)
  convert "$src" -auto-orient -resize 890x540\> "$out"
  exiftool -all= -overwrite_original "$out" >/dev/null
done

# .md-files sorted by length, to be sure parent's titles are parsed (for the breadcrumb):
mdfiles="$(find ./src -name '*.md' | awk '{ print length($0) " " $0; }' | sort -n | cut -d ' ' -f 2-)"

for src in $mdfiles; do
  echo "$src"
  out="$(echo "$src" | sed -r 's/^.\/src\//.\/docs\//' | sed -r 's/\.md$/.html/')"
  mkdir -p $(dirname $out)
  title="$(cat $src | grep -E '^# ' | head -1 | sed 's/^# //')"
  if [ "$title" = "" ]; then
      title="Telerosso"
  fi

  if [ ! -e $(dirname $src)/title.txt ]; then
    echo "$title" >$(dirname $out)/title.txt
  else
    cp $(dirname $src)/title.txt $(dirname $out)/title.txt
  fi

  breadcrumb="$(cat $(dirname $out)/title.txt)"

  pushd $(dirname $out) >/dev/null
  parent=".."
  while [ $(ls $parent/title.txt 2>/dev/null) ]; do
    parenttitle="$(cat $parent/title.txt)"
    breadcrumb="[$parenttitle]($parent/) > $breadcrumb"
    parent="../$parent"
  done
  popd >/dev/null

  cat src/header0.html | sed "s/%title%/$title/" >$out
  cat node_modules/github-markdown-css/github-markdown.css >>$out
  cat src/header1.html >>$out
  if [ "$src" = "./src/index.md" ]; then
    cat $src | $showdown makehtml -i /dev/stdin -u UTF8 >>$out
  else
    cat $src | sed "/^# /a $breadcrumb" | $showdown makehtml -i /dev/stdin -u UTF8 >>$out
  fi
  cat src/footer.html >>$out

done

for tmpfile in $(find ./docs -name 'title.txt'); do
  rm "$tmpfile"
done


