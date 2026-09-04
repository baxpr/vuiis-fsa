#!/usr/bin/env python
#
# FSA processing for a single subject, following 
# https://github.com/BingLiu-Lab/FSA/blob/a2051b11/fsa.ipynb

import copy
import joblib
import os
import numpy as np
from nilearn import image, masking
from scipy import stats, ndimage


## Set up

# load datasets 
#fmri_973 = datasets.fetch_973_fmri(center=1)
#vbf_973 = datasets.fetch_973_vbf(center=1)
#subjects = [s for s in vbf_973['subject_index'] if s[:2] == 'SZ' or s[:2] == 'NC'][:50]
#vbf = np.array(vbf_973['ALFF_GR'])[[vbf_973['subject_index'].index(s) for s in subjects]]
#fmris = np.array(fmri_973['fMRI_GR'])[[fmri_973['subject_index'].index(s) for s in subjects]]
#sample = image.load_img(fmris[0])

# Load an MNI space fmri volume to get a resampling reference
sample = image.load_img(???)

# Load MNI space striatum masks and resample to fmri geometry
path = 'path/to/FSA/Resources'
mask = image.load_img(os.path.join(path, 'mask_ICV_WB.nii.gz'))
tem6 = image.load_img(os.path.join(path, '/f6.nii.gz'))
tem8 = image.load_img(os.path.join(path, '/f8.nii.gz'))
seed_striatum = image.load_img(os.path.join(path, '/striatum.nii.gz'))

seed_striatum_res = image.resample_to_img(seed_striatum, sample, interpolation='nearest')
mask_res = image.resample_to_img(mask, sample, interpolation='nearest')
mask_tem6 = image.resample_to_img(mask, tem6, interpolation='nearest')
striatum_mask_res6 = image.resample_to_img(seed_striatum, tem6, interpolation='nearest')
striatum_mask_res8 = image.resample_to_img(seed_striatum, tem8, interpolation='nearest')
striatum_index = masking.apply_mask(seed_striatum_res, mask_res)
striatum_mask_res_data = masking.apply_mask(striatum_mask_res6, mask_tem6)


## Compute features

save_path = 'PASTE_YOUR_PATH'
def generate_FSA_candidates(name, fmris, vbf, subjects):
    
    """
    A function that parallelly extracting each individual's fMRI striatal features to 
    further compute FSA score 
    
    """
    
    for n, (fmri, falff, s) in enumerate(zip(fmris, vbf, subjects)):
        f_file = fmri
        f_img_uns = image.load_img(f_file)
        # Applying smooth when using voxel-wise features
        f_img = image.smooth_img(f_img_uns, fwhm=6)
        fmri_data_uns = masking.apply_mask(f_img_uns, mask_res)
        fmri_data = masking.apply_mask(f_img, mask_res)
#         fmri_data[np.isnan(fmri_data)] = 0
        
        # Extracting extra-striatal FC
        ts_striatum = np.mean(fmri_data_uns * striatum_index, axis=1)
        corr_striatum = np.zeros_like(striatum_index)
        for i in range(fmri_data.shape[1]):
            corr_striatum[i] = stats.pearsonr(ts_striatum, fmri_data[:, i])[0]
        corr_img = masking.unmask(corr_striatum, mask_res)
        corr_img_tem6 = image.resample_to_img(corr_img, tem6)
        str_corr = masking.apply_mask(corr_img_tem6, mask_tem6)
        str_corr[np.isnan(str_corr)] = 0
        corr_striatum_other = str_corr[striatum_mask_res_data == 0]

        # Extracting intra-striatal FC
        f_img_res = image.resample_to_img(f_img, tem8)
        ts_str = masking.apply_mask(f_img_res, striatum_mask_res8)
        corr = np.corrcoef(ts_str.T)
        fc_str = corr[np.tril_indices_from(corr, -1)]
        
        # Extracting striatal fALFF 
        striatum_seed_res = image.resample_to_img(target_img=falff, source_img=seed_striatum, interpolation='nearest')
        alff = masking.apply_mask(falff, mask_img=striatum_seed_res)

        striatal_features = np.concatenate([alff, corr_striatum_other, fc_str])
        print('Run task %s (%s)...' % (name, os.getpid()))
        joblib.dump(striatal_features, os.path.join(save_path, s + '_candidates.pkl'))
        
if __name__=='__main__':
    print('Parent process %s.' % os.getpid())
    kernels = 25
    batch = len(subjects) / kernels
    p = Pool(kernels)
    subs = [[sub for sub in subjects[batch * i: batch * i + batch]] for i in range(kernels)]
    fmri_files = [[f for f in fmris[batch * i: batch * i + batch]] for i in range(kernels)]
    vbf_files = [[f for f in vbf[batch * i: batch * i +batch]] for i in range(kernels)]
    for i in range(kernels):
        p.apply_async(generate_FSA_candidates, args=(i, fmri_files[i], vbf_files[i], subs[i]))
    print('Waiting for all subprocesses done...')
    p.close()
    p.join()
    print('All subprocesses done.')


## Compute FSA prediction and score

# Load precomputed striatal features 
striatal_features = np.zeros([len(subjects), 12689])
for i, s in enumerate(subjects):
    striatal_features[i, :] = joblib.load(os.path.join(save_path, s + '_candidates.pkl'))

# Load pre-trained model of standardizing features by all samples from 7 sites
# A new customized standardization model could be more applicable for new datasets with different races, MR scanners or preprocessing pipelines
# By using the function in following link: https://scikit-learn.org/stable/modules/generated/sklearn.preprocessing.StandardScaler.html#sklearn.preprocessing.StandardScaler

path = 'PASTE_YOUR_PATH'
prep = joblib.load(os.path.join(path, 'model_pre_final.m'))

# Load pre-trained model trained by all individuals from seven sites
# The optimal parameter was selected based on the follwing grid network:
# grid = [{'kernel': ['rbf'], 'gamma': np.logspace(np.log10(0.0001/fc.shape[1]), np.log10(10000./fc.shape[1]), 10),
#         'C': np.logspace(np.log10(0.0001), np.log10(10000), 10)}]

svc = joblib.load(os.path.join(path, 'model_final.m'))
predict = svc.predict(prep.transform(striatal_features))
test = np.array([1 if s[:2] == 'NC' else -1 for s in subjects])
print accuracy_score(predict, test)
FSA_score = svc.decision_function(prep.transform(striatal_features))
print FSA_score