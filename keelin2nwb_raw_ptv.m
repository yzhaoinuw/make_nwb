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
];  

subjectInfo = table( ...
    sex, ...
    age, ...
    'RowNames', subjectIDs, ...
    'VariableNames', {'Sex', 'Age'} ...
);

%%
%datapathsPTV_KD
%{
sessionPaths={
    '/media/knox/glymphatic/gly_Rat/24-05-05/Particles',... %KX 2
    '/media/knox/glymphatic/gly_Rat/24-05-05/Particles_001'...
    '/media/knox/glymphatic/gly_Rat/24-05-05/Particles_002'...
    '/media/knox/glymphatic/gly_Rat/24-05-05/Particles_later_001'...
    '/media/knox/glymphatic/gly_Rat/24-05-05/Particles_later'...
    '/media/knox/glymphatic/gly_Rat/24-05-05/Particles_later_002'...
    '/media/knox/glymphatic/gly_Rat/24-07-31/particles_downstream',... %KX 3
    '/media/knox/glymphatic/gly_Rat/24-07-31/particles_downstream_001',...
    '/media/knox/glymphatic/gly_Rat/24-07-31/particles_upstream_001',... %%% THIS ONE FOR EXAMPLE! %%%
    '/media/knox/glymphatic/gly_Rat/24-07-31_rat2/particles-downstream',... %KX4
    '/media/knox/glymphatic/gly_Rat/24-07-31_rat2/particles-downstream_001',...
    '/media/knox/glymphatic/gly_Rat/24-07-31_rat2/particles-downstream-bifu',...
};
%}
sessionPaths = {
    '/media/knox/glymphatic/gly_Rat/22-07-06-rat2/Particles-up-2x-001',... %from rat2, 1-4
    '/media/knox/glymphatic/gly_Rat/22-07-06-rat2/Particles-up-1x-001',...
    '/media/knox/glymphatic/gly_Rat/22-07-06-rat2/Particles-up-1x',...
    '/media/knox/glymphatic/gly_Rat/22-07-06-rat2/Particles-down-2x',...
    '/media/knox/glymphatic/gly_Rat/22-08-26-rat4/2-particles-up',... %from rat4, 5-8
    '/media/knox/glymphatic/gly_Rat/22-08-26-rat4/3-particles-down',... %6
    '/media/knox/glymphatic/gly_Rat/22-08-26-rat4/6-particles-up_001',... %7
    '/media/knox/glymphatic/gly_Rat/22-08-26-rat4/8-Particles-down_001',... %8
    '/media/knox/glymphatic/gly_Rat/23-03-31/particles-down-64min',... %23-03-31, 9
    '/media/knox/glymphatic/gly_Rat/23-03-31/particles-up2-50min',... %10
    '/media/knox/glymphatic/gly_Rat/23-03-31/particles-up-33min',... %11
    '/media/knox/glymphatic/gly_Rat/23-09-05/particles-art1-up-101min',... %23-09-05, 12
    '/media/knox/glymphatic/gly_Rat/23-09-05/particles-art2-down-79min',... %13
    '/media/knox/glymphatic/gly_Rat/23-09-05/particles-art2-up-65min',... %14
    '/media/knox/glymphatic/gly_Rat/23-09-25/particles-art1-up-58min',... %23-09-25 15
    '/media/knox/glymphatic/gly_Rat/23-09-25/particles-art1-down-71min',... %16
};

%rawFile = '/media/knox/glymphatic/gly_Rat/23-09-25/particles-art1-down-71min/Image_0001_0001.raw';
%nwbPath = '/media/knox/glymphatic/nwb_files_keelin/gly_rat_23-09-25_particles_art1_down_71min.nwb';
%subjectID = 'r-2023-9-25';
nwbDir = '/media/knox/glymphatic/nwb_files_keelin';
groupName = 'PTV';
writeDir = fullfile(nwbDir, groupName);
if ~exist(writeDir, 'dir')
mkdir(writeDir)
end

for i = 1:numel(sessionPaths)
%sessionPath = '/media/knox/glymphatic/gly_Rat/24-05-05/Particles';
sessionPath = sessionPaths{i};

[subjectPath,sessionName,~] = fileparts(sessionPath);
[experimentPath,subjectName,~] = fileparts(subjectPath);
[~,experimentName,~] = fileparts(experimentPath);
subjectID = ['r-' subjectName];
identifier = [experimentName '_' subjectName '_' sessionName];
generalSessionID = [subjectID '_' sessionName];
experimentXML = fullfile(sessionPath, 'Experiment.xml');
experimentInfo = read_Thor_xml(experimentXML);
sessionStartTime = datetime(experimentInfo.Date.date, 'InputFormat', 'MM/dd/uuuu HH:mm:ss', 'TimeZone', 'EST');
nwbPath = fullfile(writeDir, [identifier '.nwb']);
if exist(nwbPath, 'file')
    continue
end
disp(sessionPath)

nwb = NwbFile( ...
    'general_experiment_description', [experimentName, '_', groupName], ...
    'session_description', [sessionName, ', ECG, respiration'],...
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
%% raw file
rawFile = fullfile(sessionPath, 'Image_0001_0001.raw');
[img,coords,info] = read_raw(rawFile);
width = length(coords.X);
height = length(coords.Y);
nFrames = length(coords.T);
nChannels = info.NumCh;
samplingRate = info.FrameRate;

movieData = zeros(nChannels, height, width, nFrames, 'uint16');
for k = 1:nChannels
    movieData(k,:,:,:) = img{k};
end

movieData = types.untyped.DataPipe( ...
    'data', permute(movieData, [1,3,2,4]), .....
    'chunkSize', [nChannels, width, height, 100] ...
);

imageSeries = types.core.ImageSeries( ...
    'data', movieData, ...
    'description', 'movie', ...
    'data_resolution', single(info.umperpix), ...
    'data_unit', 'umperpix', ...
    'starting_time', 0.0, ... 
    'starting_time_rate', samplingRate ...
);
nwb.acquisition.set('Movies', imageSeries);

%% H5 file
thorSynPath = dir(fullfile(sessionPath, 'ThorSync*'));
thorSynPath = thorSynPath([thorSynPath.isdir]);  % keep only directories
if ~isempty(thorSynPath)
thorSyncDir = fullfile(sessionPath, thorSynPath(1).name);
h5Files = dir(fullfile(thorSyncDir, 'Episode*.h5'));
if ~isempty(h5Files)
h5File = fullfile(thorSyncDir, h5Files(1).name);
h5Info = h5info(h5File);
ecg = h5read(h5File, '/AI/ECG');
resp = h5read(h5File, '/AI/Resp');
ecgData = types.untyped.DataPipe( ...
    'data', ecg, .....
    'chunkSize', [1, 30000] ...
);
respData = types.untyped.DataPipe( ...
    'data', resp, .....
    'chunkSize', [1, 30000] ...
);
ecgSeries = types.core.TimeSeries( ...
    'description', 'ECG', ...
    'data', ecgData, ...
    'starting_time', 0, ...
    'starting_time_rate', 30000, ...
    'data_unit', 'n/a' ...
);
respSeries = types.core.TimeSeries( ...
    'description', 'Resp', ...
    'data', respData, ...
    'starting_time', 0, ...
    'starting_time_rate', 30000, ...
    'data_unit', 'n/a' ...
);
nwb.acquisition.set('ECG', ecgSeries);
nwb.acquisition.set('Resp', respSeries);
end
end
%%
nwbExport(nwb, nwbPath);
end