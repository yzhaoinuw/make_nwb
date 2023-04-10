function [nwb] = tiffs2nwb(tiffDir, xmlFile, metadataFile, nwbFilePath)

filename = strcat(mfilename('fullpath'), '.m');
[dirPath,~,~] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

if ~exist('xmlFile','var') || isempty(xmlFile)
    xmlFile = fullfile(tiffDir, 'Experiment.xml');
end

if ~exist('metadataFile','var') || isempty(metadataFile)
    metadataFile = fullfile(tiffDir, 'metadata.json');
end
disp(metadataFile);
assert(isfile(metadataFile), 'metadata.json not found. please use the metadata wizard to create one.')
metadata = jsondecode(fileread(metadataFile));

info = read_Thor_xml(xmlFile);
experiment = readExperiment(xmlFile);

time = datetime(info.Date.date);
name = info.Name;

nChannels = info.NumCh;
channelArrays = {'ChanA', 'ChanB', 'ChanC'};
channelNames = channelArrays{1:nChannels};
channelFiles = strings(1, nChannels);
for i = 1:nChannels
    channelFiles(i) = fullfile(tiffDir, [channelNames,'_0001_0001_',num2str(i,'%04d') '_0001.tif']);
end

depth = experiment.NumIm; 
tiffData = NaN(3, 512, 512, depth);
for i = 1:depth
    if mod(i,100) == 0
        disp(['Importing image ' num2str(i) ' of ' num2str(depth)])
    end

    for j = 1:nChannels
        tiffData(j, :, :, i) = uint16(imread(channelFiles(j)));
    end

end

nwb = NwbFile( ...
    'session_description', metadata.description, ... % optional, but required by inspector
    'general_session_id', metadata.sessionID, ...
    'identifier', metadata.identifier, ...
    'session_start_time', datetime(metadata.startTime), ...
    'general_experimenter', [metadata.lastName ', ' metadata.firstName], ... % optional
    'general_institution', metadata.institution, ... % optional, but preferred by inspector
    'general_keywords', metadata.keywords ...
);

% subject info
subject = types.core.Subject( ...
    'subject_id', metadata.subjectID, ...
    'age', 'P90D', ...
    'description', 'mouse 5', ... % optional, but preferred by inspector
    'species', metadata.subjectSpecies, ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', metadata.subjectSex ...
);

% tiff data
for i = 1:depth
rgbImage = types.core.RGBImage( ...
    'data', tiffData(:, :, :, i), ...  % required
    ...'resolution', 70.0, ...
    'description', ['depth_', num2str(i)] ...
);
imageCollection = types.core.Images( ...
    'description', 'Images at various depths.'...
);
imageCollection.image.set('Image', rgbImage);
end

% fill nwb files
nwb.acquisition.set('image collection', imageCollection);
nwb.general_subject = subject;

if ~exist('nwbFilePath','var') || isempty(nwbFilePath)
    nwbFilePath = fullfile(tiffDir, name);
if ~endsWith(nwbFilePath,'.nwb')
    nwbFilePath = strcat(nwbFilePath, '.nwb');
end
end

nwbExport(nwb, nwbFilePath);
end
