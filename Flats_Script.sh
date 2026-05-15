#!/usr/bin/env bash
# Flats_Script.sh — Take polarimetric flats with NIRC2
# Written by Briley Lewis (UCSB) with Claude v2.1.128 using Sonnet 4.6

# Defaults
NUM_FLATS=5
FILT=""
COADDS=1
SUBC=1024

print_usage() {
  cat <<EOF
Usage: $0 [NUM_FLATS=5] [FILT=J]

  NUM_FLATS  number of flat exposures to take (default: 5)
  FILT       filter name: J, H, Ks, Kp, K, Lw, or Lp (required)
  SUBC       subarray size in pixels (default: 1024)

  Example:
    $0 FILT=Kp NUM_FLATS=10 SUBC=512
EOF
}

for arg in "$@"; do
  if [[ "$arg" != *=* ]]; then
    echo "Error: arguments must be key=value. Got: $arg"
    print_usage
    exit 1
  fi
  key="${arg%%=*}"
  val="${arg#*=}"

  case "${key^^}" in
    NUM_FLATS) NUM_FLATS="$val" ;;
    FILT)      FILT="$val" ;;
    SUBC)      SUBC="$val" ;;
    *)
      echo "Error: unknown argument '$key'."
      print_usage
      exit 1
      ;;
  esac
done

# Validate
if ! [[ "$NUM_FLATS" =~ ^[0-9]+$ ]] || (( NUM_FLATS <= 0 )); then
  echo "Error: NUM_FLATS must be a positive integer (got '$NUM_FLATS')"
  exit 1
fi
if [[ -z "$FILT" ]]; then
  echo "Error: FILT is required. Specify e.g. FILT=Kp"
  print_usage
  exit 1
fi
if ! [[ "$SUBC" =~ ^[0-9]+$ ]] || (( SUBC <= 0 )); then
  echo "Error: SUBC must be a positive integer (got '$SUBC')"
  exit 1
fi

case "$FILT" in
  J)  TINT=30;   FILT_NUM=1  ;;
  H)  TINT=30;   FILT_NUM=2  ;;
  Ks) TINT=120;  FILT_NUM=6  ;;
  Kp) TINT=120;  FILT_NUM=7  ;;
  K)  TINT=120;  FILT_NUM=9  ;;
  Lw) TINT=0.17; COADDS=3; FILT_NUM=14 ;;
  Lp) TINT=0.17; COADDS=3; FILT_NUM=15 ;;
  *)
    echo "Error: unrecognized filter '$FILT'. Expected J, H, Ks, Kp, K, Lw, or Lp."
    exit 1
    ;;
esac

##setup bench
echo "Setting up NIRC2 for polarimetric flats with filter $FILT, subarray $SUBC, and $NUM_FLATS exposures..."
#configAOforFlats || { echo "Aborting: configAOforFlats did not complete successfully."; exit 1; }
echo "Setting domecals=true..."
modify -s dcs domecals=true
echo "Turning on flat lamps..."
modify -s dcs flimagin=0 flspectr=1
echo "Selecting narrow camera..."
camera narrow
echo "Setting filter to $FILT (filter $FILT_NUM 14)..."
filter "$FILT_NUM" 14
echo "Setting subarray to $SUBC..."
subc "$SUBC"
echo "Setting integration time..."
tint "$TINT"
echo "Setting coadds to $COADDS..."
coadds "$COADDS"
echo "Opening shutter..."
shutter open
echo "Setting object to flat..."
object flat

##take flats
echo "Taking $NUM_FLATS flat exposures with TINT=$TINT s and COADDS=$COADDS for Filter $FILT..."
goi -s "$NUM_FLATS" || { echo "goi failed"; exit 1; }
echo "Flats complete."

##turn off lamps
echo "Turning off flat lamps..."
modify -s dcs flimagin=0 flspectr=0

# Play script complete sound once at very end
modify -s nirc2plus scriptip =Yes
modify -s nirc2plus scriptip =No