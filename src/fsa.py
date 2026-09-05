#!/usr/bin/env python
#
# FSA processing for a single subject, following 
# https://github.com/BingLiu-Lab/FSA/blob/a2051b11/fsa.ipynb

import copy
import joblib
import os
import numpy
import sklearn.preprocessing
import sys
import types
from nilearn import image, masking
from scipy import stats, ndimage

# Find the path to this script
this_dir = os.path.dirname(os.path.realpath(__file__))

# Output directory
out_dir = os.path.realpath(os.path.join(this_dir,'..','OUTPUTS'))

# Preprocessed fmri inputs
fmri_nii = os.path.realpath(os.path.join(this_dir,'..','OUTPUTS','dGSRwrfmri.nii'))
falff_nii = os.path.realpath(os.path.join(this_dir,'..','OUTPUTS','fALFF_Normalised_z','fALFF_z_OUTPUTS.nii'))

# Find the FSA resources dir with striatum masks
fsa_resdir = os.path.realpath(os.path.join(this_dir,'..','external','fsa','FSA','Resources'))

print(fmri_nii)
print(falff_nii)
print(fsa_resdir)

## Set up

# load datasets 
#fmri_973 = datasets.fetch_973_fmri(center=1)
#vbf_973 = datasets.fetch_973_vbf(center=1)
#subjects = [s for s in vbf_973['subject_index'] if s[:2] == 'SZ' or s[:2] == 'NC'][:50]
#vbf = numpy.array(vbf_973['ALFF_GR'])[[vbf_973['subject_index'].index(s) for s in subjects]]
#fmris = numpy.array(fmri_973['fMRI_GR'])[[fmri_973['subject_index'].index(s) for s in subjects]]
#sample = image.load_img(fmris[0])

# Load an MNI space fmri volume to get a resampling reference
sample = image.load_img(fmri_nii)

# Load MNI space striatum masks and resample
mask = image.load_img(os.path.join(fsa_resdir, 'mask_ICV_WB.nii.gz'))
tem6 = image.load_img(os.path.join(fsa_resdir, 'f6.nii.gz'))
tem8 = image.load_img(os.path.join(fsa_resdir, 'f8.nii.gz'))
seed_striatum = image.load_img(os.path.join(fsa_resdir, 'striatum.nii.gz'))

seed_striatum_res = image.resample_to_img(seed_striatum, sample, interpolation='nearest', force_resample=True, copy_header=True)
mask_res = image.resample_to_img(mask, sample, interpolation='nearest', force_resample=True, copy_header=True)
mask_tem6 = image.resample_to_img(mask, tem6, interpolation='nearest', force_resample=True, copy_header=True)
striatum_mask_res6 = image.resample_to_img(seed_striatum, tem6, interpolation='nearest', force_resample=True, copy_header=True)
striatum_mask_res8 = image.resample_to_img(seed_striatum, tem8, interpolation='nearest', force_resample=True, copy_header=True)
striatum_index = masking.apply_mask(seed_striatum_res, mask_res)
striatum_mask_res_data = masking.apply_mask(striatum_mask_res6, mask_tem6)

# Save resampled masks
seed_striatum_res.to_filename(os.path.join(out_dir,'seed_striatum_res.nii'))
mask_res.to_filename(os.path.join(out_dir,'mask_res.nii'))
mask_tem6.to_filename(os.path.join(out_dir,'mask_tem6.nii'))
striatum_mask_res6.to_filename(os.path.join(out_dir,'striatum_mask_res6.nii'))
striatum_mask_res8.to_filename(os.path.join(out_dir,'striatum_mask_res8.nii'))

#print(help(seed_striatum_res))

#print(sample.get_sform())
#print(seed_striatum_res.get_sform())

#print(sample.get_qform())
#print(seed_striatum_res.get_qform())

#print(sample.shape)
#print(seed_striatum_res.shape)

## Compute features

f_img_uns = image.load_img(fmri_nii)

# Applying smooth when using voxel-wise features
f_img = image.smooth_img(f_img_uns, fwhm=6)
fmri_data_uns = masking.apply_mask(f_img_uns, mask_res)
fmri_data = masking.apply_mask(f_img, mask_res)
        
# Extracting extra-striatal FC
ts_striatum = numpy.mean(fmri_data_uns * striatum_index, axis=1)
corr_striatum = numpy.zeros_like(striatum_index)

for i in range(fmri_data.shape[1]):
    if numpy.std(fmri_data[:, i]) == 0:
        corr_striatum[i] = 0.0          # Prevent NaN
    else:
        corr_striatum[i] = stats.pearsonr(ts_striatum, fmri_data[:, i])[0]

corr_img = masking.unmask(corr_striatum, mask_res)
corr_img_tem6 = image.resample_to_img(corr_img, tem6, force_resample=True, copy_header=True)
str_corr = masking.apply_mask(corr_img_tem6, mask_tem6)
corr_striatum_other = str_corr[striatum_mask_res_data == 0]

# Extracting intra-striatal FC
f_img_res = image.resample_to_img(f_img, tem8, force_resample=True, copy_header=True)
ts_str = masking.apply_mask(f_img_res, striatum_mask_res8)
corr = numpy.corrcoef(ts_str.T)
fc_str = corr[numpy.tril_indices_from(corr, -1)]

# Extracting striatal fALFF 
striatum_seed_res = image.resample_to_img(target_img=falff_nii, source_img=seed_striatum, interpolation='nearest', force_resample=True, copy_header=True)
alff = masking.apply_mask(falff_nii, mask_img=striatum_seed_res)

striatal_features = numpy.concatenate([alff, corr_striatum_other, fc_str])

joblib.dump(striatal_features, os.path.join(out_dir, 'candidates.pkl'))

print(striatal_features)
print(striatal_features.shape)

## Compute FSA prediction and score

# Create an alias module for the old sklearn path used in older pickles
alias = types.ModuleType("sklearn.preprocessing.data")
alias.__dict__.update(sklearn.preprocessing.__dict__)
sys.modules["sklearn.preprocessing.data"] = alias

# Load pre-trained model of standardizing features by all samples from 7 sites
# A new customized standardization model could be more applicable for new datasets with different races, MR scanners or preprocessing pipelines
# By using the function in following link: https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.StandardScaler.html#sklearn.preprocessing.StandardScaler
prep = joblib.load(os.path.join(fsa_resdir, 'model_pre_final.m'))

# Load pre-trained model trained by all individuals from seven sites
# The optimal parameter was selected based on the follwing grid network:
# grid = [{'kernel': ['rbf'], 'gamma': numpy.logspace(numpy.log10(0.0001/fc.shape[1]), numpy.log10(10000./fc.shape[1]), 10),
#         'C': numpy.logspace(numpy.log10(0.0001), numpy.log10(10000), 10)}]
svc = joblib.load(os.path.join(fsa_resdir, 'model_final.m'))
predict = svc.predict(prep.transform(striatal_features))
FSA_score = svc.decision_function(prep.transform(striatal_features))
print(FSA_score)

