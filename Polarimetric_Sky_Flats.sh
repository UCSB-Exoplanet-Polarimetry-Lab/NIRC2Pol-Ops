#!/usr/bin/env bash
# Polarimetric_Flats.sh — Script to take polarimetric flats with NIRC2 (rotates HWP constantly through flats)
# Written by Briley Lewis with Claude v2.1.128 using Sonnet 4.6
# Modified for on sky by Jayke Nguyen

# Defaults
NUM_FLATS=5
ITIME=""
COADDS=""
PCU_ROT_POS=36000
PCU_DEFAULT_ROT_VEL=180 # deg/sec
PCU_ROT_VEL="$PCU_DEFAULT_ROT_VEL"
PADDING=1.1 # padding factor to ensure we rotate through full 360 degrees during exposures

N_CYCLES_PER_FLAT=10

print_usage() {
  cat <<EOF
  Usage: $0 NUM_FLATS=count ITIME=seconds COADDS=count [N_CYCLES_PER_FLAT=10]

  Assumes that the PCU is in place and rotation position is set to zero.

  NUM_FLATS  number of flat exposures to take (default: 5)
  ITIME      exposure integration time in seconds (required; bookkeeping only)
  COADDS     number of coadds (required; bookkeeping only)
  N_CYCLES_PER_FLAT  number of full HWP rotations per flat (default: 10)

  Example:
    $0 NUM_FLATS=10 ITIME=30 COADDS=1 N_CYCLES_PER_FLAT=8
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
  key_upper=$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')

  case "$key_upper" in
    NUM_FLATS) NUM_FLATS="$val" ;;
    ITIME)     ITIME="$val" ;;
    COADDS)    COADDS="$val" ;;
    N_CYCLES_PER_FLAT) N_CYCLES_PER_FLAT="$val" ;;
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
if [[ -z "$ITIME" ]]; then
  echo "Error: ITIME is required"
  print_usage
  exit 1
fi
if ! [[ "$ITIME" =~ ^[0-9]*\.?[0-9]+$ ]] || ! awk -v itime="$ITIME" 'BEGIN{exit !(itime > 0)}'; then
  echo "Error: ITIME must be a positive number of seconds (got '$ITIME')"
  exit 1
fi
if [[ -z "$COADDS" ]]; then
  echo "Error: COADDS is required"
  print_usage
  exit 1
fi
if ! [[ "$COADDS" =~ ^[0-9]+$ ]] || (( COADDS <= 0 )); then
  echo "Error: COADDS must be a positive integer (got '$COADDS')"
  exit 1
fi
if ! [[ "$N_CYCLES_PER_FLAT" =~ ^[0-9]+$ ]] || (( N_CYCLES_PER_FLAT <= 0 )); then
  echo "Error: N_CYCLES_PER_FLAT must be a positive integer (got '$N_CYCLES_PER_FLAT')"
  exit 1
fi

TOTAL_TIME_PER_EXP=$(awk \
  -v coadds="$COADDS" \
  -v itime="$ITIME" \
  -v padding="$PADDING" \
  'BEGIN { printf "%.2f", (6 + 12 + coadds*itime)*padding }')

PCU_ROT_POS=$(awk -v n_cycles="$N_CYCLES_PER_FLAT" 'BEGIN { printf "%.0f", n_cycles * 360 }')

PCU_ROT_VEL=$(awk -v rot_pos="$PCU_ROT_POS" -v total_time="$TOTAL_TIME_PER_EXP" \
  'BEGIN { printf "%.2f", rot_pos / total_time }')

ROTATION_LIMIT_ERROR=0
if ! awk -v pos="$PCU_ROT_POS" 'BEGIN { exit !(pos <= 36000) }'; then
  echo "Error: PCU_ROT_POS=$PCU_ROT_POS exceeds the 36000 deg limit."
  ROTATION_LIMIT_ERROR=1
fi
if ! awk -v vel="$PCU_ROT_VEL" 'BEGIN { exit !(vel <= 180) }'; then
  echo "Error: PCU_ROT_VEL=$PCU_ROT_VEL deg/sec exceeds the 180 deg/sec limit."
  ROTATION_LIMIT_ERROR=1
fi
if (( ROTATION_LIMIT_ERROR )); then
  echo "Decrease N_CYCLES_PER_FLAT (currently $N_CYCLES_PER_FLAT) and run again."
  exit 1
fi

echo "--------------------------------------------------"
echo "NIRC2 polarimetric sky flats will run with:"
echo "  NUM_FLATS          = $NUM_FLATS"
echo "  ITIME              = $ITIME"
echo "  COADDS             = $COADDS"
echo "  N_CYCLES_PER_FLAT  = $N_CYCLES_PER_FLAT"
echo "  TOTAL_TIME_PER_EXP = $TOTAL_TIME_PER_EXP"
echo "  PCU_ROT_POS        = $PCU_ROT_POS"
echo "  PCU_ROT_VEL        = $PCU_ROT_VEL"
echo "--------------------------------------------------"

read -r -p "Proceed with these settings? Make sure PCU rotation position is set to zero!!! [y/n] " CONFIRM_RUN
case "$CONFIRM_RUN" in
  ""|[Yy])
    echo "Proceeding with polarimetric sky flats..."
    ;;
  *)
    echo "Aborting."
    exit 1
    ;;
esac

cleanup() {
  echo "Resetting PCU2 to 0..."
  echo "Setting PCU position to zero..."
  modify -s pcu2 PCUPR=0
  echo "Resetting PCU2 rotation velocity to default of $PCU_DEFAULT_ROT_VEL deg/sec..."
  modify -s pcu2 PCURVEL="$PCU_DEFAULT_ROT_VEL"
}

trap cleanup EXIT # set cleanup incase anything fails

echo "Setting rotation velocity of PCU2 to $PCU_ROT_VEL deg/sec..."
modify -s pcu2 PCURVEL="$PCU_ROT_VEL" || exit 1

# rotation target positions based on default rotation velocity of 180 deg/sec of PCU

echo "Setting object to PolSkyFlat..."
object PolSkyFlat || exit 1

#set imtype
imtype calib

# take flats
echo "Taking $NUM_FLATS flat exposures with ITIME=$ITIME and COADDS=$COADDS..."

for ((i=1; i<=NUM_FLATS; i++)); do

  # Toggle HWP position
  if (( i % 2 == 1 )); then
    TARGET_POS=$PCU_ROT_POS
  else
    TARGET_POS=0
  fi

  modify -s pcu2 PCUPR="$TARGET_POS" &

  echo "Taking flat exposure... $i/$NUM_FLATS"
  goi -s || { echo "goi failed"; exit 1; }

  sleep 3 # make sure PCU isnt moving

done

cleanup
trap - EXIT

# Play script complete sound once at very end
modify -s nirc2plus scriptip=Yes || exit 1
modify -s nirc2plus scriptip=No || exit 1

echo "Flats complete."
