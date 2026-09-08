#!/bin/sh

# Working dir
WD=$(pwd)

# Where to find SPM12 on our compilation machine
SPM_PATH="${WD}"/external/spm12_r7771

# Add Matlab to the path on the compilation machine
export MATLABROOT=~/MATLAB/R2023a
export PATH=${MATLABROOT}/bin:${PATH}

# We use SPM12's standalone tool, but edited to add our own code to the 
# compilation path
matlab -nodisplay -nodesktop -nosplash -sd "${WD}" -r \
    "spm_make_standalone_local('${SPM_PATH}','${WD}/bin','${WD}/src','${WD}/../external/brant'); exit"

# We grant lenient execute permissions to the matlab executable and runscript so
# we don't have hiccups later.
chmod go+rx "${WD}"/bin/spm12
chmod go+rx "${WD}"/bin/run_spm12.sh

