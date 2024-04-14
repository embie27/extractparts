dir=$PWD

# Always cleanup
finish() {
  result=$?
  cd "$dir"
  rm -rf .temp-pages
  exit ${result}
}
trap finish EXIT ERR

STRICT=0

# Start of the script
while getopts "s" flag; do
case "$flag" in
    s) STRICT=1;;
    *) echo "rofl Usage: $0 PDFFILE SEARCHSTRING [...]"; exit 1;;
esac
done

if [ $(( $# - OPTIND + 1)) -lt 2 ]; then
  echo "Usage: $0 PDFFILE SEARCHSTRING [...]"
  exit 1
fi

filename="${*:$OPTIND:1}"

mkdir .temp-pages
echo "Extracting pages..."
pdftoppm -jpeg -r 150 "$filename" ".temp-pages/page"

cd .temp-pages
echo "Cropping images..."
for page in *.jpg; do
  convert "$page" -gravity North -crop 100x20%+0+0 -bordercolor White -border 10x10 "$page.jpg"
  mv "$page.jpg" "$page"
done
echo "Reading text..."
for page in *.jpg; do
  tesseract "$page" "$page" |& sed "s/^/$page: /"
done

for s in "${@:$OPTIND+1}"; do
  echo "Compiling document for $s."
  pages=()
  found=0
  num_pages=0
  keywords=""
  for page in *.txt; do
    if grep --quiet --ignore-case "$s" "$page"; then
      pages+=("${page:5:2}")
      num_pages=$((num_pages+1))
      if [ "$STRICT" -eq 0 ] && [ "$found" -eq 0 ]; then
        found=1
        keywords=$(tr "\n" " " < "$page" | sed "s/[[:space:]]*$s.*//i" | tr " " "|" | tr -s "|")
      fi
    elif [ "$STRICT" -eq 0 ] && [ "$found" -eq 1 ]; then
      if grep --quiet --ignore-case -E "$keywords" "$page"; then
        found=0
      else
        pages+=("${page:5:2}")
        num_pages=$((num_pages+1))
      fi
    fi
  done
  echo "Found $num_pages pages."
  if [ $num_pages -gt 0 ]; then
    cd "$dir"
    pdftk "$filename" cat "${pages[@]}" output "$filename-$s.pdf"
    cd .temp-pages
  fi
done
