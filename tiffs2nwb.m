function [nwb] = tiffs2nwb(tiffDir, xmlFile, nwbFilePath, yamlFile)

filename = strcat(mfilename('fullpath'), '.m');
[dirPath,~,~] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

if ~exist('xmlFile','var') || isempty(xmlFile)
    xmlFile = fullfile(tiffDir, 'Experiment.xml');
end

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
    'session_description', 'described the session', ... % optional, but required by inspector
    'general_experiment_description', 'Zstack in the upstream segment of a pial artery from a BPN mouse 24 min after cisterna magna injection', ...
    'general_session_id', '20210513-m1', ...
    'identifier', name, ...
    'session_start_time', time, ...
    'general_experimenter', 'Ladron de Guevara, Antonio', ... % optional
    'general_institution', 'University of Rochester', ... % optional, but preferred by inspector
    ...'general_related_publications', 'DOI', ... % optional
    'general_keywords', '20210524-m1' ...
);

% subject info
subject = types.core.Subject( ...
    'subject_id', 'BPN-OLD-M3', ...
    'age', 'P90D', ...
    'description', 'mouse 5', ... % optional, but preferred by inspector
    'species', 'Mus musculus', ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', 'M' ...
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
