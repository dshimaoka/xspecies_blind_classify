species = 'macaque';
subject = 'George';
root_dir = '/mnt/dshi0006_market/Massive/COSproject/';
save_dir = fullfile(root_dir, 'preprocessed',species,subject);


load('Neurotycho_channelLobe.mat','channelLobe','animals','lobeName');
%result of Neurorycho_channelLobe.m

animalID = find(strcmp(animals, subject));

channel = 1:size(channelLobe,1);
lobeID = channelLobe(channel,animalID);
lobe =cell(numel(channel),1);
lobe(lobeID~=0) = lobeName(lobeID(lobeID~=0));
lobe(lobeID==0) = {'N.A.'};
lobe = categorical(lobe);

nChannelByLobe = 3;
channelsByLobe = []; tgtChannels = [];
for ilobe = 1:numel(lobeName)
    %channelsByLobe{ilobe} = find(strcmp(lobeName{ilobe}, lobeName(:,animalID)))';
    channelsByLobe{ilobe} = find(channelLobe(:,animalID) == ilobe)';
    randIdx = randperm(numel(channelsByLobe{ilobe}));
    tgtChannels = [tgtChannels channelsByLobe{ilobe}(randIdx(1:nChannelByLobe))];
end

save(fullfile(save_dir,['detectChannels_' subject]) ,'channelsByLobe','tgtChannels','channel','lobe');
