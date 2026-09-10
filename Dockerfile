# Start with FSL, ImageMagick, python3/pandas, xvfb base docker
FROM baxterprogers/fsl-base:v6.0.5.2

ENV DEBIAN_FRONTEND=noninteractive

# Matlab and python2 reqs
RUN apt-get -y update \
    && apt-get -y install --no-install-recommends \
       ca-certificates \
       curl \
       openjdk-8-jre \
       python2 \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Check that certs are working
#RUN wget -S --spider https://ssd.mathworks.com/ || true
#RUN openssl s_client -connect ssd.mathworks.com:443 -servername ssd.mathworks.com </dev/null | head -n 40 || true

# Install the MCR
RUN wget -nv https://ssd.mathworks.com/supportfiles/downloads/R2023a/Release/6/deployment_files/installer/complete/glnxa64/MATLAB_Runtime_R2023a_Update_6_glnxa64.zip \
    -O /opt/mcr_installer.zip \
    && unzip /opt/mcr_installer.zip -d /opt/mcr_installer \
    && /opt/mcr_installer/install -mode silent -agreeToLicense yes \
    && rm -r /opt/mcr_installer /opt/mcr_installer.zip

# Matlab env
ENV MATLAB_SHELL=/bin/bash
ENV AGREE_TO_MATLAB_RUNTIME_LICENSE=yes
ENV MATLAB_RUNTIME=/usr/local/MATLAB/MATLAB_Runtime/R2023a
ENV MCR_INHIBIT_CTF_LOCK=1
ENV MCR_CACHE_ROOT=/tmp

# Python 2 environment for FSA script
COPY src/requirements.txt /tmp/requirements.txt
RUN curl -sS https://bootstrap.pypa.io/pip/2.7/get-pip.py -o /tmp/get-pip.py \
    && python2 /tmp/get-pip.py \
    && rm -f /tmp/get-pip.py \
    && pip2 install --no-cache-dir -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

# Copy the pipeline code
COPY external/fsa /opt/vuiis-fsa/external/fsa
COPY external/spm12_r7771/spm12/tpm /opt/vuiis-fsa/external/spm12_r7771/spm12/tpm
COPY matlab /opt/vuiis-fsa/matlab
COPY src /opt/vuiis-fsa/src
COPY README.md /opt/vuiis-fsa/README.md

# Add pipeline to system path
ENV PATH /opt/vuiis-fsa/src:/opt/vuiis-fsa/matlab/bin:${PATH}

# Matlab executable must be run at build to extract the CTF archive
RUN run_spm12.sh ${MATLAB_RUNTIME} function quit

# Entrypoint
ENTRYPOINT ["xwrapper.sh","pipeline_entrypoint.sh"]
