#!/usr/bin/env bash
# Polarimetric_Flats.sh — Script to take polarimetric flats with NIRC2 (rotates HWP constantly through flats)
# Written by Briley Lewis with Claude v2.1.128 using Sonnet 4.6

# Defaults
NUM_FLATS=5
FILT="J"
COADDS=1
SUBC=1024
PCU_ROT_POS=36000

print_usage() {
  cat <<EOF
Usage: $0 [NUM_FLATS=5] [FILT=J]

  NUM_FLATS  number of flat exposures to take (default: 5)
  FILT       filter name: J, H, K/Kp/Ks, or L/Lp (default: J)
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
  echo "Error: FILT cannot be empty"
  exit 1
fi
if ! [[ "$SUBC" =~ ^[0-9]+$ ]] || (( SUBC <= 0 )); then
  echo "Error: SUBC must be a positive integer (got '$SUBC')"
  exit 1
fi

# rotation target positions based on default rotation velocity of 180 deg/sec of PCU
case "$FILT" in
  J)  TINT=30;   FILT_NUM=1  ; PCU_ROT_POS=6300;
  H)  TINT=30;   FILT_NUM=2  ; PCU_ROT_POS=6300;
  Ks) TINT=120;  FILT_NUM=6  ; PCU_ROT_POS=24000;
  Kp) TINT=120;  FILT_NUM=7  ; PCU_ROT_POS=24000;
  K)  TINT=120;  FILT_NUM=9  ; PCU_ROT_POS=24000;
  Lw) TINT=0.17; COADDS=3; FILT_NUM=14 ; PCU_ROT_POS=1800;
  Lp) TINT=0.17; COADDS=3; FILT_NUM=15 ; PCU_ROT_POS=1800;
  *)
    echo "Error: unrecognized filter '$FILT'. Expected J, H, Ks, Kp, K, Lw, or Lp."
    exit 1
    ;;
esac

##setup bench
echo "Setting up NIRC2 for polarimetric flats with filter $FILT, subarray $SUBC, and $NUM_FLATS exposures..."
configAOforFlats
echo "Setting domecals=true..."
modify -s dcs domecals=true
echo "Turning on flat lamps..."
modify -s dcs flimagin=0 flspectr=1
echo "Selecting narrow camera..."
camera narrow
echo "Setting subarray to $SUBC..."
subc "$SUBC"
echo "Opening shutter..."
shutter open
echo "Setting object to PolFlat..."
object PolFlat

##Check HWP motion
echo "Checking HWP status..."
HWP_POS=$(show -s pcu2 PCUPR)
modify -s pcu2 PCUPR=$HWP_POS+45
HWP_POS_NEW=$(show -s pcu2 PCUPR)
if [[ "$HWP_POS_NEW" = "$HWP_POS"+45 ]]; then
  echo "HWP moved successfully to $HWP_POS_NEW degrees. Continuing setup."
else
  echo "Error: HWP did not move. Current position: $HWP_POS degrees. Please complete troubleshooting and run this script again."
  exit 1
fi

##Move in PCU
echo "Inserting PCU2 to hwp_center..."
modify -s pcu2 PCUNAME=hwp_center

##Move in Field Mask
echo "Inserting 5x10 field mask..."
modify -s nirc2 slmname=5arcsec_wide

##Moving in Wollaston
echo "Inserting Wollaston prism and setting filter to $FILT..."
filter $FILT_NUM 14

##Continuously rotating HWP
echo "Starting continuous HWP rotation..."
##NOTE: NEED TO EXPERIMENT WITH HOW LONG HWP ROTATES SO WE CAN MAKE SURE IT CONTINUES ROTATING THROUGH ALL FLATS
modify -s pcu2 PCUPR=$PCU_ROT_POS &

##take flats
echo "Taking $NUM_FLATS flat exposures with TINT=$TINT s and COADDS=$COADDS for Filter $FILT..."
tint $TINT
coadds $COADDS
goi -s "$NUM_FLATS" || { echo "goi failed"; exit 1; }
echo "Flats complete."

##turn off lamps
echo "Turning off flat lamps..."
modify -s dcs flimagin=0 flspectr=0

# Play script complete sound once at very end
modify -s nirc2plus scriptip =Yes
modify -s nirc2plus scriptip =No
