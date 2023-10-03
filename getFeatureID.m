function featureID = getFeatureID(operations, featureName)


featureID = find(contains(operations.CodeString, featureName));
