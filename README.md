# xspecies_blind_classify

Utility functions/scripts
addDirPrefs_COS.m: 
extractLobes.m: 

Data preprocessing:
- preprocess_toru.m: macaque ECoG data
- preprocess_kirill.m: human ECoG data
Functions involved:
- preprocessOneCh.m

HCTSA:
1, main_hctsa_1_init.m: Initialization to compute HCTSA
2, main_hctsa_2_compute_local.m: Main HCTSA computation. consumes days per channel
3, main_hctsa_3_postProcess.m: Exclude features
Functions involved:

Nearest-median classification per channel:
Scripts:
1, awake_unconscious_NMclassification_channels.m: train & validate NM classifier between all channel combinations
2, show_resultMatrix.m: show NM classifier performance (matrix and violin plot)
Functions:
NMclassifier_cv.m: 
classification_nearestMean/get_sig_features.m
getConsistency.m: consistency metric across trials