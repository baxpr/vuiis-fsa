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


# Build a single-page PDF courtesy of GPT-5.2:
magick -units PixelsPerInch -density 300 \
  \( reg.png  -auto-orient -resize 2250x \
     -background white -gravity north -splice 0x90 \
     -gravity north -font Helvetica -pointsize 14 -fill black \
     -annotate +0+25 "Subject WM on subject mean fMRI (native space)" \
  \) \
  \( reg2.png -auto-orient -resize 2250x \
     -background white -gravity north -splice 0x200 \
     -gravity north -font Helvetica -pointsize 14 -fill black \
     -annotate +0+125 "Template GM on subject mean fMRI (MNI space)" \
  \) \
  -append \
  -background white -gravity center -bordercolor white -border 150x0 \
  -background white -gravity north -splice 0x280 \
  -gravity north -font Helvetica-Bold -pointsize 18 -fill black \
  -annotate +0+100 "${label_str}" \
  -background white -gravity north -extent 2550x3300 \
  \( -size 2550x3300 xc:none -set page +0+0 \
     -gravity south -font Helvetica -pointsize 12 -fill "#444" \
     -annotate +0+150 "$(date '+%Y-%m-%d %H:%M:%S %Z')" \
  \) \
  -set page +0+0 -gravity south -composite \
  +repage \
  output.png

magick output.png fsa-registrations.pdf
