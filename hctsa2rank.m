function rank = hctsa2rank(TS_data)
%order = hctsa2order(TS_data)
%returns order from low to high, normalized between 0 - 1

[nEpochs, nFeatures] = size(TS_data);
rank = nan(nEpochs,nFeatures);
for ff = 1:nFeatures
    TS_data_c = TS_data(:,ff);

    %[~,idx] = sort(TS_data_c);
    rank(:,ff) = tiedrank(TS_data_c) / nEpochs;
end