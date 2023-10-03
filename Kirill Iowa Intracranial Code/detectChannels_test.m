uiopen('/mnt/dshi0006_market/Massive/COSproject/Kirill Iowa Intracranial Data/376R_Electrode_Sites_KN_DS.xlsx',1);

channel = RElectrodeSitesKNDS.Channel;
region = RElectrodeSitesKNDS.region; %8 functional regions
lobe = RElectrodeSitesKNDS.lobe; %4 anatomical lobes

%regionNames = categories(region);
lobeNames = {'occipital','parietal','temporal','frontal'};%categories(lobe);

nChannelByLobe = 3;
channelsByLobe = []; tgtChannels = [];
for ilobe = 1:numel(lobeNames)
    channelsByLobe{ilobe} = find(strcmp(lobeNames{ilobe}, string(lobe)))';
    randIdx = randperm(numel(channelsByLobe{ilobe}));
    tgtChannels = [tgtChannels channelsByLobe{ilobe}(randIdx(1:nChannelByLobe))];
end

save('detectChannels_test','channelsByLobe','tgtChannels','lobeNames');
