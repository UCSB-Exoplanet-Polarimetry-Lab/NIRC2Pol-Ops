#!/usr/bin/env bash
# Darks_Script.sh — Script to take dark frames with NIRC2
# Automatically searches FITS files from the night to see which combinations of coadds, itime, and sampmode were used
# Originally written by Jayke Nguyen (UCSD), edited by Briley Lewis (UCSB)

# --------------------

usage() {
    echo "Usage: $(basename "$0") <folder> [file_pattern]"
    echo ""
    echo "  <folder>        Path to the directory containing FITS files (required)"
    echo "  [file_pattern]  Glob pattern for FITS files (default: n0*.fits)"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") /sdata907/nirc7/2025dec21/"
    echo "  $(basename "$0") /sdata907/nirc7/2025dec21/ n1*.fits"
    exit 0
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

if [[ -z "$1" ]]; then
    echo "Error: <folder> is required." >&2
    usage
fi

FOLDER="$1"
FILE_PATTERN="${FOLDER}${2:-n0*.fits}"

# Commented out status messages so the output is clean code
# echo "Scanning files matching: $FILE_PATTERN"

# fitsheader columns:
# $1: File, $2: NAXIS1, $3: NAXIS2, $4: COADDS, $5: ITIME, $6: SAMPMODE, $7: READS

fitsheader -f -k NAXIS1 -k NAXIS2 -k COADDS -k ITIME -k SAMPMODE -k READS $FILE_PATTERN 2>/dev/null \
| awk 'NR>2 && NF>0 {print $2, $3, $5, $4, $6, $7}' \
| sort \
| uniq -c \
| awk 'BEGIN {
    print "#!/bin/csh -f"
    print ""
    print "object dark"
    print "shutter close"
    print ""
}
{
    # $1: Count
    # $2: NAXIS1
    # $3: NAXIS2
    # $4: ITIME
    # $5: COADDS
    # $6: SAMPMODE
    # $7: READS
    
    print "# Found " $1 " frames with configuration below:"
    print "subc " $2 " " $3   # Sets subc NAXIS1 NAXIS2
    print "sampmode " $6
    print "nsamp " int($7/2)  # Divide READS by 2 for nsamp
    print "tint " $4
    print "coadd " $5
    print "goi -s 10"
    print ""
}'
