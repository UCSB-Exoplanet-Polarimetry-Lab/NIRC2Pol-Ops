FOLDER="/sdata907/nirc3/2026may27/"
FILE_PATTERN="${FOLDER}${1:-n0*.fits}"

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
    print "imtype dark"
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

cd /home/nirc2eng/vis/jnguyen
