#!/usr/bin/env bash
# NIRC2p_Setup.sh — Script to do basic setup of NIRC2 Pol mode, inserts HWP, Wollaston, field mask
# Written by Briley Lewis (UCSB)

read -p "Have you started NIRC2? (y/n): " answer
case "$answer" in
    [Yy]|[Yy][Ee][Ss]) ;;  # accepted, do nothing and continue
    *)
        echo "Aborting. Please start NIRC2 first."
        exit 1
        ;;
esac

##basic NIRC2 setup
aohatch open
shutter open
camera narrow
subc 1024

##AO bench clearing
echo "Checking AO bench stages..."
status=$(show -s ao obdbname)
if [[ "$status" != "home" ]]; then
  modify -s ao obdbname home
fi

status=$(show -s ao obdbimname)
if [[ "$status" != "home" ]]; then
  modify -s ao obdbimname home
fi

status=$(show -s ao obofname)
if [[ "$status" != "home" ]]; then
  modify -s ao obofname home
fi

##Open GUI
echo "Opening NIRC2 GUI..."
xshow -s ao pcupr obrt pcuname -s nirc2 slmname &

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
echo "Inserting Wollaston prism (with J band default)..."
filter 1 14

echo "NIRC2-Pol setup complete."
echo "USER RESPONSIBILITY: Make sure NIRC2 is selected on FACSUM, open GUIs, check PIG, make newdir, add scripts to path."
echo "Please take a test image to confirm setup is correct before proceeding with science observations."