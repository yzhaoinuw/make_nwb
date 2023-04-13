rawFile = 'C:\Users\Yue\matlab_projects\brainwaveZZZ\ati-pen1-33min\Image_0001_0001.raw';
rawDir = 'C:\Users\Yue\matlab_projects\brainwaveZZZ\ati-pen1-33min\';
nwbFilePath = '.\brainwavezzz\Image_0001_0001.nwb';
[img,coords,info]=read_raw(rawFile);
[nr, nc, depth] = size(img{1});
rawData = NaN(3, nr, nc, depth);

for i = 1:length(img)
    rawData(i, :, :, :) = img{i};
end

if ~exist('xmlFile','var') || isempty(xmlFile)
    xmlFile = fullfile(rawDir, 'Experiment.xml');
end

if ~exist('metadataFile','var') || isempty(metadataFile)
    metadataFile = fullfile(rawDir, 'metadata.json');
end

assert(isfile(metadataFile), 'metadata.json not found. please use the metadata wizard to create one.')
metadata = jsondecode(fileread(metadataFile));

experiment = readExperiment(xmlFile);
name = info.Name;

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
    'date_of_birth', metadata.subjectDOB, ...
    ... 'description', 'mouse 5', ... % optional, but preferred by inspector
    'species', metadata.subjectSpecies, ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', metadata.subjectSex, ...
    'strain', metadata.subjectStrain ...
);

% tiff data
for i = 1:depth
rgbImage = types.core.RGBImage( ...
    'data', rawData(:, :, :, i), ...  % required
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
    nwbFilePath = fullfile(rawDir, name);

if ~endsWith(nwbFilePath,'.nwb')
    nwbFilePath = strcat(nwbFilePath, '.nwb');
end
end

nwbExport(nwb, nwbFilePath);
