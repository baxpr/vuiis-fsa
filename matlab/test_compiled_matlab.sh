#!/usr/bin/env bash

export PATH=$(pwd)/bin:$PATH

run_spm12.sh \
    /home/rogersbp/MATLAB/R2023a \
    function matlab_entrypoint \
    fmri_niigz $(pwd)/../INPUTS/fmri.nii.gz \
    fmri_json $(pwd)/../INPUTS/fmri.json \
    t1_niigz $(pwd)/../INPUTS/t1.nii.gz \
    t1_json $(pwd)/../INPUTS/t1.json \
    out_dir $(pwd)/../OUTPUTS
