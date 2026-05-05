#!/usr/bin/env bash
# Darks_Script.sh — Script to take dark frames with NIRC2
# Automatically searches FITS files from the night to see which combinations of coadds, itime, and sampmode were used
# Originally written by Jayke Nguyen (UCSD), edited by Briley Lewis (UCSB) with Claude Code v2.1.128 (Sonnet 4.6)

# This script writes a .csh file with the commands to take darks needed
# Inspect the resulting .csh file and remove any unnecessary darks (e.g. combinations of parameters with only one or two frames)
# Run the .csh file to take your darks automatically

# --------------------

usage() {
    echo "Usage: $(basename "$0") <data_folder> <output_folder> [file_pattern]"
    echo ""
    echo "  <data_folder>    Path to the directory containing FITS files (required)"
    echo "  <output_folder>  Path to the directory to write the output .csh file (required)"
    echo "  [file_pattern]   Glob pattern for FITS files (default: n0*.fits)"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") /sdata907/nirc7/2025dec21/ /home/user/scripts/"
    echo "  $(basename "$0") /sdata907/nirc7/2025dec21/ /home/user/scripts/ n1*.fits"
    exit 0
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

if [[ -z "$1" ]]; then
    echo "Error: <data_folder> is required." >&2
    usage
fi

if [[ -z "$2" ]]; then
    echo "Error: <output_folder> is required." >&2
    usage
fi

DATA_FOLDER="$1"
OUTPUT_FOLDER="$2"
FILE_PATTERN="${DATA_FOLDER}${3:-n0*.fits}"
OUTPUT_FILE="${OUTPUT_FOLDER%/}/$(date +%Y%m%d)_darks_script.csh"

echo "Writing output to: $OUTPUT_FILE" >&2

# fitsheader columns:
# $1: File, $2: NAXIS1, $3: NAXIS2, $4: COADDS, $5: ITIME, $6: SAMPMODE, $7: READS

fitsheader -f -k NAXIS1 -k NAXIS2 -k COADDS -k ITIME -k SAMPMODE -k READS $FILE_PATTERN 2>/dev/null \
| awk 'NR>2 && NF>0 {print $2, $3, $5, $4, $6, $7}' \
| sort \
| uniq -c \
| awk '{
    n++
    cnt[n]=$1; nx1[n]=$2; nx2[n]=$3; itime[n]=$4; coadds[n]=$5; samp[n]=$6; reads[n]=$7
    total += $4 * $5
}
END {
    h = int(total / 3600)
    m = int((total % 3600) / 60)
    s = total % 60
    print "#!/bin/csh -f"
    print ""
    print "# Approximate total runtime: " total " seconds (" h "h " m "m " s "s)"
    print ""
    print "object dark"
    print "shutter close"
    print ""
    for (i = 1; i <= n; i++) {
        print "# Found " cnt[i] " frames with configuration below:"
        print "subc " nx1[i] " " nx2[i]
        print "sampmode " samp[i]
        print "nsamp " int(reads[i]/2)
        print "tint " itime[i]
        print "coadd " coadds[i]
        print "goi -s 10"
        print ""
    }
}' > "$OUTPUT_FILE"
