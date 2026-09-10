# Start with FSL, ImageMagick, python3/pandas, xvfb base docker
FROM baxterprogers/fsl-base:v6.0.5.2

ENV DEBIAN_FRONTEND=noninteractive

# Matlab reqs
RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
    openjdk-8-jre && \
    apt-get clean
        
# Install the MCR
RUN wget -nv https://ssd.mathworks.com/supportfiles/downloads/R2023a/Release/6/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2023a_Update_6_glnxa64.zip \
    -O /opt/mcr_installer.zip && \
    unzip /opt/mcr_installer.zip -d /opt/mcr_installer && \
    /opt/mcr_installer/install -mode silent -agreeToLicense yes && \
    rm -r /opt/mcr_installer /opt/mcr_installer.zip

# Matlab env
ENV MATLAB_SHELL=/bin/bash
ENV AGREE_TO_MATLAB_RUNTIME_LICENSE=yes
ENV MATLAB_RUNTIME=/usr/local/MATLAB/MATLAB_Runtime/R2023a
ENV MCR_INHIBIT_CTF_LOCK=1
ENV MCR_CACHE_ROOT=/tmp

# Copy the pipeline code
COPY matlab /opt/vuiis-fsa/matlab
COPY src /opt/vuiis-fsa/src
COPY README.md /opt/vuiis-fsa/README.md

# Python 2 environment for FSA script
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    python2 \
    ca-certificates \
    curl && \
    curl -sS https://bootstrap.pypa.io/pip/2.7/get-pip.py -o /tmp/get-pip.py && \
    python2 /tmp/get-pip.py && \
    apt-get clean && \
    rm -f /tmp/get-pip.py && \
    rm -rf /var/lib/apt/lists/* && \
    pip2 install --no-cache-dir -r /opt/vuiis-fsa/src/requirements.txt

# Add pipeline to system path
ENV PATH /opt/vuiis-fsa/src:/opt/vuiis-fsa/matlab/bin:${PATH}

# Matlab executable must be run at build to extract the CTF archive
RUN run_spm12.sh ${MATLAB_RUNTIME} function quit

# Entrypoint
ENTRYPOINT ["xwrapper.sh","pipeline_entrypoint.sh"]
