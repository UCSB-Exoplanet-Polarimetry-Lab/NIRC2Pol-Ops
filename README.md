# NIRC2-Pol Operations Software

Last Updated: 29 April 2026

NIRC2 Polarimetry (NIRC2-Pol, or nirc2p) is a dual-channel polarimetry mode on the Keck II NIRC2 infrared imager. Dual-channel polarimetry uses a polarizing beamsplitter to split the incoming light into two orthogonal polarization states, and a half-wave plate (HWP) to modulate the angle of polarization. Through cycles of four critical HWP angles (0°, 45°, 22.5°, 67.5°), it is possible to recover the linear Stokes vector components Q and U (see de Boer+ 2020 for a description of dual-channel polarimetry and double differencing). 

NIRC2-Pol enables polarimetric observations in JHKL’ bands in combination with multiple existing NIRC2 modes, such as grism spectroscopy and high-contrast coronagraphic imaging, and both NGS and LGS AO. This is useful for many science cases, from solar system objects to circumstellar disks and active galactic nuclei. NIRC2-Pol was developed as part of the Precision Calibration Unit (PCU2) project on Keck II. 

**About this repository**

This repository contains scripts for efficiently operating the NIRC2 Polarimetry mode. The most officially up-to-date versions of operations scripts will soon be transferred to and managed with Keck's internal SVN version control, where observatory staff will maintain them.

Related code lives in other repositories:

- [NIRC2Pol-DPP](https://github.com/UCSB-Exoplanet-Polarimetry-Lab/NIRC2Pol-DPP) — data processing pipeline for the mode
- [pyPolCal](https://github.com/UCSB-Exoplanet-Polarimetry-Lab/pyPolCal) — instrumental polarization calibration. Archived release: [`doi:10.5281/zenodo.20752634`](https://doi.org/10.5281/zenodo.20752634)
- [pyMuellerMat](https://github.com/UCSB-Exoplanet-Polarimetry-Lab/pyMuellerMat) — Mueller matrix modelling. Archived release: [`doi:10.5281/zenodo.20752256`](https://doi.org/10.5281/zenodo.20752256)

**Files in this repo**

- [Folder] `Commissioning Analysis` = Various files and scripts from use in commissioning; kept as a "historical record"
- [Folder] `docs/efficiency-calc` = Source for the observing time calculator, published via GitHub Pages
- `Fast_Axis_Cal_Sequence.sh` = Takes data 0 to 180 deg in steps of 10 for use in finding the fast axis of a HWP.
- `HWP_Rotation_Sequence.sh` = Used for typical observing sequences (four critical angles: 0, 45, 22.5, 67.5 deg)
- `Internal_Pol_Cal_Sequence.sh` = Takes data rotating both HWP and IMR for instrumental polarization calibration
- `Flats_Script.sh` = Takes regular dome flats for a user-specified filter (do not use on sky!)
- `Darks_Script.sh` = Generates script to take necessary darks based on images in a specified folder
- `Polarimetric_Flats.sh` = Takes polarimetric dome flats (i.e. HWP continuously rotating) (do not use on sky!)

**Syntax for using each script**

`bash Fast_Axis_Cal_Sequence.sh FILTER=[filter]`

`bash HWP_Rotation_Sequence.sh KWARG=[KEYWORD_VALUE]`

`bash Internal_Pol_Cal_Sequence.sh FILTER=[filter]`

`bash Flats_Script.sh FILT=[filter]`

`bash Darks_Script.sh <data_folder> <output_script_folder>`

`bash Polarimetric_Flats.sh FILT=[filter]`

See the Operations Guide below for a full description of these commands and their various options/keywords.

**Observing time calculator**

HWP cycling makes NIRC2-Pol considerably more expensive than straight imaging, so total elapsed time is worth estimating before a run. An interactive calculator is available at:

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

Only `nread - 1` reads are charged, as the first is absorbed by the integration. These are planning estimates and exclude acquisition, focus, and calibration.

**Operations/Observer's Guide**

The NIRC2-Pol operations/observer's guide is available in two forms:

- [Working copy](https://docs.google.com/document/d/1xZ5t1CYUM9_GUHD_lKeaxhGwf5xAPUc301j2dv2oiKI/edit?tab=t.v9hqfo1pspp7#heading=h.ej8cynj3sfoq) (Google Doc) — edited first, so normally the most current version. Start here when observing.
- [Archived release](https://doi.org/10.5281/zenodo.20737935) (Zenodo, `doi:10.5281/zenodo.20737935`) — a citable snapshot of the working copy, published periodically. Use this one for citation.

See also the [NIRC2 Observer's Manual](https://www2.keck.hawaii.edu/inst/nirc2/ObserversManual.html) for the instrument as a whole.

**Citation and Acknowledgements**

To acknowledge the use of the NIRC2 Polarimetry mode, including code from this repo, please cite Lewis et al. in prep (the NIRC2-Pol first light paper). See below for a BibTeX entry, which will be soon updated.
```
@article{lewis2026nirc,
  title={NIRC2-Pol: First Light of Near-Infrared Polarimetry on Keck II},
  author={Lewis, Briley L. and Zhang, Rebecca and Millar-Blanchaer, Maxwell and Marin, Eduardo and Nguyen, Jayke and Melby, William and others},
  year={In Prep.}
}
```

If using the NIRC2-Pol DPP and/or the Mueller matrix model of the instrument (both currently under development), there will be SPIE proceedings for those coming Summer 2026--Lewis et al. 2026 and Zhang et al. 2026, respectively.

NIRC2-Pol PI: Max Millar-Blanchaer (UCSB)
NIRC2-Pol Team: Rebecca Zhang, Briley Lewis (UCSB); Jayke Nguyen (UCSD), Ryan Hersey (UCSB), Will Melby (U of A), Thomas McIntosh (UCSB), Mike Fitzgerald (UCLA), Dimitri Mawet (Caltech), Nem Jovanovic (Caltech), Keith Matthews (Caltech)
PCU2 Team: Jessica Lu, Charles-Antoine Claveau, Matthew Freeman (Berkeley); Eduardo Marin, Scott Lilley, Ed Wetherell, Jacob Taylor, Mahawa Cisse, Lauren Simmons, Paul Richards, Carlos Alvarez, Percy Gomez, Kittrin Matthews, Max Service, Trisha Harmmen, Jim Lyke (Keck)

