#!/usr/bin/env bash
# Split the compiled draft (main paper + supplement in one PDF) into the two submission files:
#   submission/STAGS_main.pdf          pages 1 .. last page before "Supplementary Material"
#   submission/STAGS_supplementary.pdf "Supplementary Material" title page .. end
# Usage: ./make_submission.sh [combined.pdf]
#   combined.pdf defaults to main.pdf (e.g. downloaded from Overleaf); if it does not exist and tectonic is
#   available (TECTONIC=/path/to/tectonic), main.tex is compiled first.
# Section, figure, equation and citation numbers in the supplement continue those of the main paper, because both
# come from one LaTeX run; links between the two files are not clickable. Needs poppler (pdfinfo, pdftotext,
# pdfseparate, pdfunite).
set -euo pipefail
cd "$(dirname "$0")"
IN=${1:-main.pdf}
if [[ ! -e $IN ]]; then
    "${TECTONIC:-tectonic}" -X compile main.tex
    IN=main.pdf
fi
n=$(pdfinfo "$IN" | awk '/^Pages:/{print $2}')
split=""
for p in $(seq 1 "$n"); do
    if grep -qx "Supplementary Material" <<< "$(pdftotext -f "$p" -l "$p" "$IN" -)"; then split=$p; break; fi
done
[[ -n $split ]] || { echo "no 'Supplementary Material' title page found in $IN" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
quiet() { "$@" 2> >(grep -v "Found recursive dicts" >&2); }   # poppler warns once per object on hyperref PDFs
quiet pdfseparate "$IN" "$tmp/p-%04d.pdf"
mkdir -p submission
quiet pdfunite $(for p in $(seq 1 $((split - 1))); do printf '%s/p-%04d.pdf ' "$tmp" "$p"; done) submission/STAGS_main.pdf
quiet pdfunite $(for p in $(seq "$split" "$n"); do printf '%s/p-%04d.pdf ' "$tmp" "$p"; done) \
    submission/STAGS_supplementary.pdf
echo "main paper:    pages 1-$((split - 1)) -> submission/STAGS_main.pdf"
echo "supplementary: pages $split-$n -> submission/STAGS_supplementary.pdf"
# the main text (before References) must end on page 8
refs=""
for p in $(seq 1 $((split - 1))); do
    if grep -qx "References" <<< "$(pdftotext -f "$p" -l "$p" "$IN" -)"; then refs=$p; break; fi
done
echo "References start on page ${refs:-?} (main text must end by page 8)"
