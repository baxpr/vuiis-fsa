#!/usr/bin/env bash

export MATLAB_RUNTIME=$HOME/MATLAB/R2023a

export LD_LIBRARY_PATH=\
$MATLAB_RUNTIME/runtime/glnxa64:\
$MATLAB_RUNTIME/bin/glnxa64:\
$MATLAB_RUNTIME/sys/os/glnxa64:\
$MATLAB_RUNTIME/sys/opengl/lib/glnxa64

export PATH=$(pwd):$(pwd)/../matlab/bin:$PATH

pipeline_entrypoint.sh
