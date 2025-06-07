addpath('/media/yue/make_nwb/matnwb/')

subjectIDs = {
    '22-07-06-rat2'; 
    '22-08-26-rat4'; 
    '23-03-31'; 
    '23-09-05';
    '23-09-25';
    '24-05-05';
    '24-07-31';
    '24-07-31_rat2';
    '24-04-28';
 };     % a cell array of IDs (one per row)

sex = {
    'M'; 
    'M'; 
    'M'; 
    'M';
    'M';
    'F';
    'M';
    'M';
    'F';
};         
% matching cell array of sex
age = [
    54; 
    105; 
    68; 
    58;
    78;
    67;
    70;
    70;
    61;
];  

subjectInfo = table( ...
    sex, ...
    age, ...
    'RowNames', subjectIDs, ...
    'VariableNames', {'Sex', 'Age'} ...
);

%% Zstack_KD
%{
sessionPaths={
    '/media/knox/glymphatic/gly_Rat/24-07-31/Zstack-downstream2',...
    '/media/knox/glymphatic/gly_Rat/24-07-31/Zstack-upstream',...
    '/media/knox/glymphatic/gly_Rat/24-07-31_rat2/zstack-downstream-bifu',...
    '/media/knox/glymphatic/gly_Rat/24-07-31_rat2/zstack-upstream',...
    '/media/knox/glymphatic/gly_Rat/24-04-28/Zstack-art1_bright'...
    '/media/knox/glymphatic/gly_Rat/24-05-05/Zstack_001'...
    '/media/knox/glymphatic/gly_Rat/24-05-05/Zstack_002'... %Also has great penetrating PVS!
};
%}

%% Zstack_Rats
sessionPaths = {
    '/media/knox/glymphatic/gly_Rat/22-07-06-rat2/zstasck-up-1x',...        % 1
    '/media/knox/glymphatic/gly_Rat/22-08-26-rat4/5-Zstack-up',... %2 
    '/media/knox/glymphatic/gly_Rat/23-03-31/Zstack-up',...
    '/media/knox/glymphatic/gly_Rat/22-08-26-rat4/7-Zstack-down',... %4
    '/media/knox/glymphatic/gly_Rat/23-03-31/Zstack-down',...
    '/media/knox/glymphatic/gly_Rat/23-09-05/zstack-art2-up-97min',... %6
    '/media/knox/glymphatic/gly_Rat/23-09-05/zstack-art2-down-92min',...
    '/media/knox/glymphatic/gly_Rat/23-09-05/zstack-art1-up-118min_001',...
    '/media/knox/glymphatic/gly_Rat/23-09-25/zstack-art1-down-80min',...
    '/media/knox/glymphatic/gly_Rat/23-09-25/zstack-art1-up-68min',...
};
nwbDir = '/media/knox/glymphatic/nwb_files_keelin';
groupName = 'Zstack_Rats';
writeDir = fullfile(nwbDir, groupName);
if ~exist(writeDir, 'dir')
mkdir(writeDir)
end

for k = 1:numel(sessionPaths)
%sessionPath = '/media/knox/glymphatic/gly_Rat/24-07-31/Zstack-downstream2';    
sessionPath = sessionPaths{k};

[subjectPath,sessionName,~] = fileparts(sessionPath);
[experimentPath,subjectName,~] = fileparts(subjectPath);
[~,experimentName,~] = fileparts(experimentPath);
subjectID = ['r-' subjectName];
identifier = [experimentName '_' subjectName '_' sessionName];
generalSessionID = [subjectID '_' sessionName];
experimentXML = fullfile(sessionPath, 'Experiment.xml');
experimentInfo = readExperiment(experimentXML);
thorInfo = read_Thor_xml(experimentXML);

nwbPath = fullfile(writeDir, [identifier '.nwb']);
if exist(nwbPath, 'file')
    continue
end

disp(sessionPath)
sessionStartTime = datetime(thorInfo.Date.date, 'InputFormat', 'MM/dd/uuuu HH:mm:ss', 'TimeZone', 'EST');
samplingRate = experimentInfo.frameRate;
height = experimentInfo.pixelY;
width = experimentInfo.pixelX;
depth = experimentInfo.NumZ;
nChannels = 3;


%tifFile = '/media/knox/glymphatic/gly_Rat/24-07-31/Zstack-downstream2/ChanC_0001_0001_0332_0001.tif';
%tifInfo = imfinfo(tifFile);

nwb = NwbFile( ...
    'general_experiment_description', [experimentName, '_', groupName], ...
    'session_description', sessionName,...
    'identifier', identifier, ...
    'session_start_time', sessionStartTime, ...
    'general_experimenter', 'Ladron de Guevara, Antonio', ... % optional
    'general_session_id', generalSessionID, ... % optional
    'general_institution', 'University of Rochester', ... % optional
    'general_keywords', 'Glymphatic, Perivascular space, Periarterial space, Cerebrospinal fluid.' ...
);
%% subject info
sex = subjectInfo{subjectName, 'Sex'};   % returns {'M'}
ageDays = subjectInfo{subjectName, 'Age'}; 
ageDays = 'P' + string(ageDays) + 'D';
subject = types.core.Subject( ...
    'subject_id', subjectID, ...
    'age', char(ageDays), ...
    'description', 'Sprague Dawley rat from Charles River.', ... % optional, but preferred by inspector
    'species', 'Rattus norvegicus', ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', sex, ...
    'strain', '001' ...
);
nwb.general_subject = subject;
%%
channelArrays = {'ChanA', 'ChanB', 'ChanC'};
channelNames = channelArrays{1:nChannels};
tiffData = zeros(nChannels, height, width, depth);

for i = 1:nChannels
    for j = 1:depth  %for zstack
        if mod(j, 100) == 0
            disp(['Importing image ' num2str(j) ' of ' num2str(depth)])
        end
        tiffFile = fullfile(sessionPath, [channelArrays{i}, '_0001_0001_', num2str(i,'%04d'), '_0001.tif']);
        tiffData(i, :, :, j) = uint16(imread(tiffFile));   
    end
end

zstackData = types.untyped.DataPipe( ...
    'data', permute(tiffData, [1,3,2,4]), .....
    'chunkSize', [nChannels, width, height, 100] ...
);

imageSeries = types.core.ImageSeries( ...
    'data', zstackData, ...
    'description', 'z-stack images at 1-micron increments', ...
    'data_resolution', single(thorInfo.umperpix), ...
    'data_unit', 'umperpix', ...
    'starting_time', 0.0, ... 
    'starting_time_rate', samplingRate ...
);
nwb.acquisition.set('Z-stack images', imageSeries);
%%
nwbExport(nwb, nwbPath);
end