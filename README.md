# xspecies_blind_classify

Utility functions/scripts
addDirPrefs_COS.m: 
extractLobes.m: 
NeurotychoChannelGroup: retrieve channel group (8)
NeurotychoChannelLobe: retrieve channel lobe (4)

Data preprocessing:
Scripts
- preprocess_toru.m: macaque ECoG data
- preprocess_kirill.m: human ECoG data
- showChannelLocationsByLobe: locations of channels for each lobe (macaque only)
- (showChannelLocations_test.m: show locations of channels on the cortex (macaque only))
Functions:
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
TrainNMClassifier:
ValidateNMClassifier: 
classification_nearestMean/get_sig_features.m
getConsistency.m: consistency metric across trials
show_NMclassifier_single.m: scatter plot of accuracy of all valid operations

Support-vector machine classification using all operations:
Functions:
SVMclassifier_cv: train classifier using fitclinear (ridge/lasso regression) for each cross-validation partition then validate using predict
show_SVMclassifier_single: show histogram of weights averaged across partitions
parcellateEpochs: create partitions for cross-validation cf.cvpartition

Visualizing results
show_resultMatrix.m: creates following figures 
    resultMatrix_nm_(violin)_xx: accuracy on trained and validation data using nm classifier
    resultMatrix_svm_(violin)_xx: accuracy on trained and validation data using svm classifier
    svmWeights_train_train_xx_validate_xx: 
    resultMatrix_svm_nm(_violin): improved accuracy on validation data using svm against nm
    overlapOperations_svm_nm: 
show_result_trainTypes: use result of show_resultMatrix, create figures comparing accuracy by NM and SVM