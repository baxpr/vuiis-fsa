#!/usr/bin/env bash

MR=$HOME/MATLAB/R2023a
export LD_LIBRARY_PATH=$MR/runtime/glnxa64:$MR/bin/glnxa64:$MR/sys/os/glnxa64:$MR/sys/opengl/lib/glnxa64
export PATH=$(pwd):$(pwd)/../matlab/bin:$PATH

pipeline_entrypoint.sh
