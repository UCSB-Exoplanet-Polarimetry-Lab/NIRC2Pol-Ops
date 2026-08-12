# NIRC2-Pol Operations Software

Last Updated: 12 Aug 2026

NIRC2 Polarimetry (NIRC2-Pol, or nirc2p) is a dual-channel polarimetry mode on the Keck II NIRC2 infrared imager. Dual-channel polarimetry uses a polarizing beamsplitter to split the incoming light into two orthogonal polarization states, and a half-wave plate (HWP) to modulate the angle of polarization. Through cycles of four critical HWP angles (0°, 45°, 22.5°, 67.5°), it is possible to recover the linear Stokes vector components Q and U (see de Boer+ 2020 for a description of dual-channel polarimetry and double differencing). 

NIRC2-Pol enables polarimetric observations in JHKL’ bands in combination with multiple existing NIRC2 modes, such as grism spectroscopy and high-contrast coronagraphic imaging, and both NGS and LGS AO. This is useful for many science cases, from solar system objects to circumstellar disks and active galactic nuclei. NIRC2-Pol was developed as part of the Precision Calibration Unit (PCU2) project on Keck II. 

## About this repository

This repository contains scripts for efficiently operating the NIRC2 Polarimetry mode. Many of these are ``helper'' scripts that the observer can use at their discretion by uploading them into their personal user folder on Keck servers. Only `HWP_Rotation_Sequence.sh` is available by default on the Keck networks/version control / is officially supported.

**Files in this repo**

- [Folder] `Commissioning Analysis` = Various files and scripts from use in commissioning; kept as a "historical record"
- [Folder] `docs/` = Source for the efficiency calculator and SNR calculator, published via GitHub Pages
- `HWP_Rotation_Sequence.sh` = Used for typical observing sequences (four critical angles: 0, 45, 22.5, 67.5 deg)
- `Internal_Pol_Cal.sh` = Takes data rotating both HWP and IMR for instrumental polarization calibration. Options available for dome and sky (needed due to differences in IMR operation on sky vs. daytime cals)
- `Continuous_Pol_Flats.sh` = Takes polarimetric dome flats (i.e. HWP continuously rotating). Note that this is _not_ currently the recommended strategy for flats; we suggest taking them at the typical HWP Angles. Options available for dome and sky observations
- `Dark_Script_Generation.sh` = Creates a darks script to automatically take darks for all observing configurations used during the night.

**Basic syntax for using each script**

`bash HWP_Rotation_Sequence.sh KWARG=[KEYWORD_VALUE]`

`bash Internal_Pol_Cal.sh FILTER=[filter]`

`bash Continuous_Pol_Flats.sh FILT=[filter]`

For the darks script: manually edit the first line to specify which folder it should point to for scanning your night's observations, and the last line to tell it which directory to use. Run your edited script with `bash Dark_Script_Generation.sh > darks_MMDDYYYY.csh` and then check the output file. If there are any settings where only one or two frames are found, or settings for which you don't need darks, delete them from the output script. Then, run the output script with `bash darks_MMDDYYYY.csh`

See the Operations Guide below for a full description of these commands and their various options/keywords.

## Operations/Observer's Guide

The NIRC2-Pol operations/observer's guide is available in two forms:

- [Working copy](https://docs.google.com/document/d/1xZ5t1CYUM9_GUHD_lKeaxhGwf5xAPUc301j2dv2oiKI/edit?tab=t.v9hqfo1pspp7#heading=h.ej8cynj3sfoq) (Google Doc) — edited first, so normally the most current version. Start here when observing.
- [Archived release](https://doi.org/10.5281/zenodo.20737935) (Zenodo, `doi:10.5281/zenodo.20737935`) — a citable snapshot of the working copy, published periodically. Use this one if a citation is needed.

See also the [NIRC2 Observer's Manual](https://www2.keck.hawaii.edu/inst/nirc2/ObserversManual.html) for the instrument as a whole.

## Observing efficiency and SNR calculators

Planning observations with NIRC2-Pol? An interactive efficiency calculator is available at:

**https://ucsb-exoplanet-polarimetry-lab.github.io/NIRC2Pol-Ops/efficiency-calc/**

Its cadence inputs correspond to the keywords of `HWP_Rotation_Sequence.sh` (`NUM_EXPOSURES`, `HWP_CYCLES`). The underlying estimate is:

```
t_elapsed(sec) = 6*(ndither+1)
               + 4*(12+1)*ndither*nframes*ncycles
               + 4*ndither*nframes*ncycles*coadds*(itime + tread*(nread-1))
```

where `nframes` is the number of frames at each HWP angle, `tread` is the NIRC2 readout time (0.18 sec for the full 1024x1024 array; 0.05 sec for a 512x512 sub-array), and `nread` is the number of reads (2 for CDS, 2n for MCDS-n). The factor of 4 throughout is the four HWP angles in a cycle. The constants are:

- **6 sec** = AO overhead during a dither (open loops, move telescope, reposition FSMs, reposition WFS focus, close TT loop, close DM loop)
- **12 sec** = time to read and write a NIRC2 image including FITS information
- **1 sec** = time for the HWP rotation command; the stage moves quickly, but this covers processing and sending the command

Only `nread - 1` reads are charged, as the first is absorbed by the integration. These are planning estimates and exclude acquisition, focus, and calibration. This equation is based on the original NIRC2 equations for efficiency, but includes HWP cycling.

Similarly, we have implemented the framework for polarimetric high-contrast imaging SNR from Nguyen, M. M., Jensen-Clem, R., Millar-Blanchaer, M. A., Mukherjee, S., Skemer, A. & Wang, J. 2021, “An exposure time calculator for high-contrast polarimeters,” Proc. SPIE 11823, 118231X, [doi:10.1117/12.2597978](https://doi.org/10.1117/12.2597978). By inputting your target's magnitude and expected polarization, plus a target SNR and exposure settings, you can figure out what observations are needed to reach your goals. You can find this SNR calculator at:

**https://ucsb-exoplanet-polarimetry-lab.github.io/NIRC2Pol-Ops/exposure-time-calc/**

Note that this SNR calculator has _not_ yet been rigorously tested, so use at your own risk.

## Citation and Acknowledgements

To acknowledge the use of the NIRC2 Polarimetry mode, including code from this repo, please cite Lewis et al. in prep (the NIRC2-Pol first light paper). See below for a BibTeX entry, which will be soon updated.
```
@article{lewis2026nirc,
  title={NIRC2-Pol: First Light of Near-Infrared Polarimetry on Keck II},
  author={Lewis, Briley L. and Zhang, Rebecca and Millar-Blanchaer, Maxwell and Marin, Eduardo and Nguyen, Jayke and Melby, William and others},
  year={In Prep.}
}
```

If using the NIRC2-Pol DPP and/or the Mueller matrix model of the instrument (both currently under development), there will be SPIE proceedings for those coming Summer 2026--Lewis et al. 2026 and Zhang et al. 2026, respectively.

**Related Code**

Related code lives in other repositories:

- [NIRC2Pol-DPP](https://github.com/UCSB-Exoplanet-Polarimetry-Lab/NIRC2Pol-DPP) — data processing pipeline for the mode
- [pyPolCal](https://github.com/UCSB-Exoplanet-Polarimetry-Lab/pyPolCal) — instrumental polarization calibration. Archived release: [`doi:10.5281/zenodo.20752634`](https://doi.org/10.5281/zenodo.20752634)
- [pyMuellerMat](https://github.com/UCSB-Exoplanet-Polarimetry-Lab/pyMuellerMat) — Mueller matrix modelling. Archived release: [`doi:10.5281/zenodo.20752256`](https://doi.org/10.5281/zenodo.20752256)

---------------------------
NIRC2-Pol PI: Max Millar-Blanchaer (UCSB)
NIRC2-Pol Core Team: Briley Lewis, Rebecca Zhang (UCSB); Jayke Nguyen (UCSD)
Contact: Briley Lewis, brileylewis@ucsb.edu
