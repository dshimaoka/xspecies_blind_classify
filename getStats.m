function data = getStats(species, subject)
%data = getStats(species, subject)

data = struct;
data.species = species;
data.subject = subject;
switch species
    case 'macaque'
    switch subject
        case 'George'
            data.date = 20120803;
            data.ndosage = 1;
            %data.eyeopen =
            data.state = {'awake','unconscious'};
            data.sex = 'unknown';
            data.age = [];
            data.dose = [0 5.2]; %Yanagawa 2011 Suppl6
            data.doseunit = 'mg/Kg';
            data.anesthetic = 'propofol';
            data.source_dir = '20120803PF_Anesthesia+and+Sleep_George_Toru+Yanagawa_mat_ECoG128';
    end
    
    case 'human'

        switch subject
            case '369'
                data.expIDs = {'130' '135'};
                data.state = {'awake','unconscious'};

            case '376'
                data.expIDs = {'139' '146'};
                data.state = {'awake','unconscious'};
                data.sex = 'female';
                data.age = 48;
                data.dose = [0 150]; %Nourski 2018 fig1D
                data.doseunit = 'ug/kg/min';
                data.anesthetic = 'propofol';
        end


end
