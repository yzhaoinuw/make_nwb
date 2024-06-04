clear;

rawDir = '/media/knox/glymphatic/20200525_FunctionalHyperemia_Stephanie/Two z-planes - dilation propagation/2021-09-10 #312/#312_5threc_0um/';
rawDir = '';

filename = strcat(mfilename('fullpath'), '.m');
[dirPath,~,~] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

maskFile = fullfile(rawDir, 'Results.mat');
xmlFile = fullfile(rawDir, 'Experiment.xml');
rawFile=fullfile(rawDir, 'Image_0001_0001.raw');
%masks = load(maskFile);
info = read_Thor_xml(xmlFile);
experiment = readExperiment(xmlFile);


if ~exist('metadataFile','var') || isempty(metadataFile)
    metadataFile = fullfile(rawDir, dir([rawDir 'meta*.json']).name);
    %metadataFile = fullfile(rawDir, 'metadata_5threc_0.json');
end

assert(isfile(metadataFile), 'metadata.json not found. please use the metadata wizard to create one.')
metadata = jsondecode(fileread(metadataFile));

time = datetime(info.Date.date);
name = info.Name;
frameRate = info.FrameRate;
nChannels = info.NumCh;
width = info.ImageWidth
height = info.ImageHeight
channelArrays = {'ChanA', 'ChanB', 'ChanC'};
channelNames = {'chanA', 'chanB', 'chanC'};
indicatorArrays = {'GFP', 'GFP', 'beta-Act-GFP'};
depth = experiment.NumZ;
time = experiment.NumT;

[img,coords,info]=read_raw(rawFile);
[nr, nc, ~] = size(img{1});

% if depth>1
%     rawData = zeros(nChannels, width, height, depth);
% else
%     rawData = zeros(nChannels, width, height, time);
% end
rawData= zeros(time, depth, width, height, nChannels);

for i = 1:nChannels

    if depth>1
        
      rawData(time, :, :, :, i) = permute(img{i},[3 1 2]);
    
        

    else
        
      rawData(:, depth, :, :, i) = permute(img{i},[3 1 2]);
    
        
        
    end

end


nwb = NwbFile( ...
    'session_description', metadata.sessionDescription, ... % optional, but required by inspector
    'general_experiment_description', metadata.experimentDescription, ...
    'general_session_id', metadata.sessionID, ...
    'identifier', metadata.identifier, ...
    'session_start_time', datetime(metadata.startTime), ...
    'general_experimenter', metadata.experimenter, ... % optional
    'general_institution', metadata.institution, ... % optional, but preferred by inspector
    'general_keywords', metadata.keywords ...
);


device = types.core.Device( ...
    'description', metadata.microscope, ...
    'manufacturer', metadata.manufacturer ...
);
channelData = metadata.channelData;
nwb.general_devices.set('Device', device);
img_seg = types.core.ImageSegmentation();

% subject info
ageDays = ceil(days(datetime(metadata.startTime) - datetime(metadata.subjectDOB)));
ageDays = 'P' + string(ageDays) + 'D';
subject = types.core.Subject( ...
    'subject_id', metadata.subjectID, ...
    'age', char(ageDays), ...
    ...'description', 'Jackson Labs, JAX stock #006567', ... % optional, but preferred by inspector
    'species', metadata.subjectSpecies, ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', metadata.subjectSex, ...
    'strain', metadata.subjectStrain ...
);


for i = 1:nChannels
    disp(i)
    optical_channel = types.core.OpticalChannel( ...
        'description', channelArrays{i}, ...
        'emission_lambda', channelData.(channelNames{i}).emissionLambda ...
    );

    imaging_plane_name = ['imaging_plane', num2str(i)];
    imaging_plane = types.core.ImagingPlane( ...
        'optical_channel', optical_channel, ...
        'description', ['Imaging plane for ', channelArrays{i}], ...
        'device', types.untyped.SoftLink(device), ...
        'excitation_lambda', channelData.(channelNames{i}).excitationLambda, ...
        'imaging_rate', frameRate, ...
        'indicator', channelData.(channelNames{i}).indicator, ...
        'location', metadata.location, ...
        'grid_spacing_unit', 'arbitrary unit' ...
    );
    nwb.general_optophysiology.set(imaging_plane_name, imaging_plane);
    
    disp("piping")
    twoPhotonData = types.untyped.DataPipe( ...
        'data', permute(rawData( :, :, :, :, i), [4,3,2,1]), ...
        ...'chunkSize', [1, 1, width, height], ...
        'chunkSize', [height, width, 1, 1] ...
    );

    image_series = types.core.TwoPhotonSeries( ...
        'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
        'starting_time', 0.0, ...
        'starting_time_rate', metadata.startingTimeRate, ...
        'description', ['Two-photon series for ', channelArrays{i}], ...
        'data', twoPhotonData, ...
        'data_unit', 'arbitrary unit' ...
    );
    nwb.acquisition.set(['TwoPhotonSeries', channelArrays{i}], image_series);
   %{
    plane_segmentation = types.core.PlaneSegmentation( ...
        'colnames', {'image_mask'}, ...
        'description', ['Plane segmentation for ', channelArrays{i}], ...
        'id', types.hdmf_common.ElementIdentifiers('data', int32(1:depth)), ...
        'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
        'image_mask', types.hdmf_common.VectorData( ...
            'data', logical(masks.seg_img{i}), ...
            'description', ['Image masks for ', channelArrays{i}] ...
        ) ...
    );
    % img_seg = types.core.ImageSegmentation();
    img_seg.planesegmentation.set(['PlaneSegmentation', channelArrays{i}], plane_segmentation);
    %}
    
end

ophys_module = types.core.ProcessingModule( ...
    'description',  'contains optical physiology data' ...
);
%ophys_module.nwbdatainterface.set('ImageSegmentation', img_seg);
%nwb.processing.set('ophys', ophys_module);
nwb.general_subject = subject;

if ~exist('nwbFilePath','var') || isempty(nwbFilePath)
    nwbFilePath = fullfile(rawDir, name);
if ~endsWith(nwbFilePath,'.nwb')
    nwbFilePath = strcat(nwbFilePath, '.nwb');
end
end
nwbExport(nwb, nwbFilePath);