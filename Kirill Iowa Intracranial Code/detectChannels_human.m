subject = '376';
root_dir = '/mnt/dshi0006_market/Massive/COSproject/';
save_dir = fullfile(root_dir, 'preprocessed');

uiopen('/mnt/dshi0006_market/Massive/COSproject/Kirill Iowa Intracranial Data/376R_Electrode_Sites_KN_DS.xlsx');
%open the 2nd tab for LGD experiment (readme.txt)

channel = RElectrodeSitesKNDSS1.Channel;
region = RElectrodeSitesKNDSS1.region; %8 functional regions
lobe = RElectrodeSitesKNDSS1.lobe; %4 anatomical lobes

%regionNames = categories(region);
lobeNames = {'occipital','parietal','temporal','frontal'};%categories(lobe);

nChannelByLobe = 3;
channelsByLobe = []; tgtChannels = [];
for ilobe = 1:numel(lobeNames)
    channelsByLobe{ilobe} = find(strcmp(lobeNames{ilobe}, string(lobe)))';
    randIdx = randperm(numel(channelsByLobe{ilobe}));
    tgtChannels = [tgtChannels channelsByLobe{ilobe}(randIdx(1:nChannelByLobe))];
end

save(fullfile(save_dir,['detectChannels_' subject]) ,'channelsByLobe','tgtChannels','lobeNames',...
    'channel','lobe');
