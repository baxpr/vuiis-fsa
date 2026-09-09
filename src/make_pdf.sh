#!/usr/bin/env bash

export out_dir=$(pwd)/../OUTPUTS

# c1t1.nii   gray matter
# c2t1.nii   white matter
# c3t1.nii   CSF

cd "${out_dir}"

# Subject white matter outline on subject mean fmri
fslmaths c2t1 -thr 0.9 -edge -thr 0.3 wmedge
fsleyes render --outfile reg.png --size 1800 600 --hideCursor --scene ortho meanfmri --cmap greyscale wmedge --cmap red 

# Template gray matter outline on subject MNI fmri
fslroi ../external/spm12_r7771/spm12/tpm/TPM gm_template 0 1
fslmaths gm_template -thr 0.6 -edge -thr 0.2 gmedge_template
fsleyes render --outfile reg2.png --size 1800 600 --worldLoc 10 0 0 --hideCursor --scene ortho wrfmri --cmap greyscale gmedge_template --cmap red 

