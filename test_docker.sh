#!/usr/bin/env bash

docker run \
    --mount type=bind,src=$(pwd -P)/INPUTS,dst=/INPUTS \
    --mount type=bind,src=$(pwd -P)/OUTPUTS,dst=/OUTPUTS \
    vuiis-fsa:test \
    --fmri_niigz /INPUTS/fmri.nii.gz \
    --fmri_json /INPUTS/fmri.json \
    --t1_niigz /INPUTS/t1.nii.gz \
    --t1_json /INPUTS/t1.json \
    --label_str "Test Subject/Session" \
    --out_dir /OUTPUTS
