#!/usr/bin/env bash
# Polarimetric_Flats.sh — Script to take polarimetric flats with NIRC2 (rotates HWP constantly through flats)
# Written by Briley Lewis with Claude v2.1.128 using Sonnet 4.6
# Modified for on sky by Jayke Nguyen

# Defaults
NUM_FLATS=5
PCU_ROT_POS=36000

print_usage() {
  cat <<EOF
Usage: $0 [NUM_FLATS=5]

  NUM_FLATS  number of flat exposures to take (default: 5)

  Example:
    $0 NUM_FLATS=10
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

cleanup() {
  echo "Resetting PCU2 to 0..."
  modify -s pcu2 PCUPR=0
}

trap cleanup EXIT # set cleanup incase anything fails

# rotation target positions based on default rotation velocity of 180 deg/sec of PCU

echo "Setting object to PolSkyFlat..."
object PolSkyFlat || exit 1

##Move in PCU
echo "Inserting PCU2 to hwp_center..."
modify -s pcu2 PCUNAME=hwp_center || exit 1 # move pcu to position
modify -s pcu2 PCUPR=0 || exit 1 # move pcu location to zero

##take flats
echo "Taking $NUM_FLATS flat exposures..."

modify -s pcu2 PCUPR="$PCU_ROT_POS" &
sleep 1 # just to make sure we're going

for ((i=1; i<=NUM_FLATS; i++)); do

  echo "Taking flat exposure... $i/$NUM_FLATS"
  goi -s || { echo "goi failed"; exit 1; }

done

trap - EXIT
modify -s pcu2 PCUPR=0 # reset to zero

# Play script complete sound once at very end
modify -s nirc2plus scriptip=Yes
modify -s nirc2plus scriptip=No

echo "Flats complete."
