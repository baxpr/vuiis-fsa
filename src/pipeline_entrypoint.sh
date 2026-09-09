#!/usr/bin/env bash

# Initialize defaults. Use these filenames for FSA processing to work as written
export fmri_niigz=/INPUTS/fmri.nii.gz
export fmri_json=/INPUTS/fmri.json
export t1_niigz=/INPUTS/t1.nii.gz
export t1_json=/INPUTS/t1.json
export out_dir=/OUTPUTS

# Parse input options
while [[ $# -gt 0 ]]; do
    key="${1}"
    case $key in   
        --fmri_niigz) export fmri_niigz="${2}"; shift; shift ;;
        --fmri_json)  export fmri_json="${2}";  shift; shift ;;
        --t1_niigz)   export t1_niigz="${2}";   shift; shift ;;
        --t1_json)    export t1_json="${2}";    shift; shift ;;
        --out_dir)    export out_dir="${2}";    shift; shift ;;
        *) echo "Input ${1} not recognized" ; shift ;;
    esac
done

# Matlab preprocessing
run_spm12.sh \
    ${MATLAB_RUNTIME} \
    function matlab_entrypoint \
    fmri_niigz "${fmri_niigz}" \
    fmri_json "${fmri_json}" \
    t1_niigz "${t1_niigz}" \
    t1_json "${t1_json}" \
    out_dir "${out_dir}"

# FSA score
fsa.py \
	--fmri_nii "${out_dir}"/dGSRwrfmri.nii \
	--falff_nii "${out_dir}"/fALFF_Normalised_z/fALFF_z_OUTPUTS.nii \
	--out_dir "${out_dir}"

# PDF report
