# xspecies_blind_classify

## **Utility functions/scripts**
- addDirPrefs_COS.m: 
- extractLobes.m: 
- NeurotychoChannelGroup: retrieve channel group (8)
- NeurotychoChannelLobe: retrieve channel lobe (4)
- getCondTrials: from TimeSeries data (result of HCTSA) and specified condition(s), return condition id of each epoch
- clusterFeatures: reorder columns based on correlation-distance clustering

## **Channel information:**
- detectChannels_macaque.m
- detectChannels_human.m: read 376R_Electrode_Sites_KN_DS.xlsx, randomly select xx channels from each lobe
- preprocessed/(species)/(subject)/detectChannels_(subject).mat: lobeName of each channel
- (detectChannels_376.mat fixed lobe(136)=lobe(144) = parietal)
- compareValidation.m:  compute correlation between species, compute matching channels saved as compareValidation.mat

## **Data preprocessing:**
- preprocess_toru.m: macaque ECoG data
- preprocess_kirill.m: human ECoG data
- showChannelLocationsByLobe: locations of channels for each lobe (macaque only)
- (showChannelLocations_test.m: show locations of channels on the cortex (macaque only))
- preprocessOneCh.m

## **HCTSA:**
1. main_hctsa_1_init.m: Initialization to compute HCTSA
2. main_hctsa_2_compute_local.m: Main HCTSA computation. consumes days per channel
3. main_hctsa_3_postProcess.m: Exclude features


## **Nearest-median classification per channel:**
- NMclassification_selectCh.m: train & validate NM classifier between selected channel combinations, creating following figures:
  - histograms of single epochs of selected features (fig2)
  - barcode of hctsa of all epochs (fig2)
  - barcode of classification accuracy (fig2)
- show_resultMatrix.m: show NM classifier performance (matrix and violin plot)
- NMclassifier_cv.m:
- TrainNMClassifier:
- ValidateNMClassifier: 
- getValidFeatures: exclude features that include 1) constant values or 2)NaN. Features with Inf are kept
- classification_nearestMean/get_sig_features.m
- getConsistency.m: consistency metric across trials, created from main_directionConsistency by AL
- show_NMclassifier_single.m: scatter plot of accuracy of all valid operations Called in NMclassification_selectCh.m, but not for fig 2
- get_sig_features.m: Get features which perform significantly better than chance after FDR correction for multiple corrections, on valid features. Called in NMclassification_selectCh.m

## **Support-vector machine classification using all operations:**
- SVMclassifier_cv: train classifier using fitclinear (ridge/lasso regression) for each cross-validation partition then validate using predict
- show_SVMclassifier_single: show histogram of weights averaged across partitions
- parcellateEpochs: create partitions for cross-validation cf.cvpartition

## **Visualizing results:**
- compareValidation.m: scatter plot classification accuracy macaque v human for fig, producing
  - compareValidation.mat: housing validFeatures_all, mean_accuracy_all, sigFeatures
  - nsig_accuracy.fig: # significant features per channel and lobe (Fig4)
- show_resultMatrix.m: creates following figures 
  - resultMatrix_nm_(violin)_xx: accuracy on trained and validation data using nm classifier
  - resultMatrix_svm_(violin)_xx: accuracy on trained and validation data using svm classifier
  - svmWeights_train_train_xx_validate_xx: 
  - resultMatrix_svm_nm(_violin): improved accuracy on validation data using svm against nm
  - overlapOperations_svm_nm: 
- show_result_trainTypes: use result of show_resultMatrix, create figures comparing accuracy by NM and SVM
- showSingleEpochHists: show histograms of a given feature index
- pdensity_awakeUnconscious: show histogram of a given feature across epochs for fig2
- compareValidation.m: compare validation accuracy between human and monkey
- showHCTSAbarcodes.m
- NMclassification_nEpochs: nEpochs vs classification accuracy for fig3
