addpath('/media/yue/make_nwb/matnwb/')

subjectIDs = {
    '20210315_PTV_BPN-BPH'; 
    '20210524_PTV_BPN-BPH'; 
    '20210525_PTV_BPN-BPH'; 
    '20210526_PTV_BPN-BPH';
    '20210527_PTV_BPN';
 };     % a cell array of IDs (one per row)

sex = {
    'M'; 
    'F'; 
    'F';
    'F';
    'M';

};         
% matching cell array of sex
age = [
    196; 
    290; 
    291;
    292;
    281;
];  

subjectInfo = table( ...
    sex, ...
    age, ...
    'RowNames', subjectIDs, ...
    'VariableNames', {'Sex', 'Age'} ...
);

%%
%%Mouse comparisons - BPN WT mice data 
% upload the Image_0001_0001.raw and ECG and resp in h5 file in ThorSync
sessionPaths={
    %'/media/knox/glymphatic/gly_BPN/20210315_PTV_BPN-BPH/M1/particles',... %M1
    %'/media/knox/glymphatic/gly_BPN/20210524_PTV_BPN-BPH/1-Normal_Pressure/particles-down',...    %M2
    %'/media/knox/glymphatic/gly_BPN/20210525_PTV_BPN-BPH/Normal_Pressure/particles-up',...    %M3
    '/media/knox/glymphatic/gly_BPN/20210526_PTV_BPN-BPH/particles-up_001',...    %M4
    %'/media/knox/glymphatic/gly_BPN/20210527_PTV_BPN/1-Normal_Pressure/particles-up' %M5
};      

%rawFile = '/media/knox/glymphatic/gly_Rat/23-09-25/particles-art1-down-71min/Image_0001_0001.raw';
%nwbPath = '/media/knox/glymphatic/nwb_files_keelin/gly_rat_23-09-25_particles_art1_down_71min.nwb';
%subjectID = 'r-2023-9-25';
nwbDir = '/media/knox/glymphatic/nwb_files_keelin';
groupName = 'BPN_WT_Mice ';
writeDir = fullfile(nwbDir, groupName);
if ~exist(writeDir, 'dir')
mkdir(writeDir)
end

for i = 1:numel(sessionPaths)
%sessionPath = '/media/knox/glymphatic/gly_Rat/24-05-05/Particles';
sessionPath = sessionPaths{i};
%{
[typePath,sessionName,~] = fileparts(sessionPath);
[subjectPath,typeName,~] = fileparts(typePath);
[experimentPath,subjectName,~] = fileparts(subjectPath);
[~,experimentName,~] = fileparts(experimentPath);
subjectID = ['m-' subjectName];
identifier = [experimentName '_' subjectName '_' typeName '_' sessionName];
generalSessionID = [subjectID '_' typeName '_' sessionName];
%}
[subjectPath,sessionName,~] = fileparts(sessionPath);
[experimentPath,subjectName,~] = fileparts(subjectPath);
[~,experimentName,~] = fileparts(experimentPath);
subjectID = ['m-' subjectName];
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
    'description', 'Mouse from Charles River.', ... % optional, but preferred by inspector
    'species', 'Mus musculus', ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', sex, ...
    'strain', 'C57BL/6' ...
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