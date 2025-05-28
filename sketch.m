clear;

%tiffDir = '.\brainwaveZZZ\z-stack-up-48min\';
tiffDir ='Mouse305_1strec_0um/';
metadataFile='Mouse305_1strec_0um/metadata_1strec_0.json';

filename = strcat(mfilename('fullpath'), '.m');
[dirPath,~,~] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

%maskFile = fullfile(tiffDir, 'Results.mat');
xmlFile = fullfile(tiffDir, 'Experiment.xml');

%masks = load(maskFile);
info = read_Thor_xml(xmlFile);
experiment = readExperiment(xmlFile);

if ~exist('metadataFile','var') || isempty(metadataFile)
    metadataFile = fullfile(tiffDir, 'metadata.json');
end

assert(isfile(metadataFile), 'metadata.json not found. please use the metadata wizard to create one.')
metadata = jsondecode(fileread(metadataFile));

startTime = datetime(metadata.startTime);
name = info.Name;
frameRate = info.FrameRate;
nChannels = info.NumCh;
width = info.ImageWidth
height = info.ImageHeight
channelArrays = {'ChanA', 'ChanB', 'ChanC'};
channelNames = {'chanA', 'chanB', 'chanC'};

depth = experiment.NumZ;
time = experiment.NumT;

% %Try swapping the dimensions
% depth = experiment.NumT;
% time = experiment.NumZ;

tiffData = zeros(time, depth, width, height, nChannels);

for i = 1:nChannels
    if depth>1
        
        for j = 1:depth  %for zstack
            if mod(j, 500) == 0
                disp(['Importing image ' num2str(j) ' of ' num2str(depth)])
            end
            %tiffFile = fullfile(tiffDir, [channelArrays{i}, '_0001_0001_0001_', num2str(j,'%04d'), '.tif']);
            tiffFile = fullfile(tiffDir, [channelArrays{i}, '_0001_0001_', num2str(i,'%04d'), '_', num2str(j,'%04d'), '.tif']);
            tiffData( time, j, :, :, i) = uint16(imread(tiffFile));
            
        end
        

    else
        
        for j = 1:time %for time stack
            if mod(j, 500) == 0
                disp(['Importing image ' num2str(j) ' of ' num2str(time)])
            end
            %tiffFile = fullfile(tiffDir, [channelArrays{i}, '_0001_0001_0001_', num2str(j,'%04d'), '.tif']);
            tiffFile = fullfile(tiffDir, [channelArrays{i}, '_0001_0001_', num2str(i,'%04d'), '_', num2str(j,'%04d'), '.tif']);
            tiffData(j,depth, :, :, i) = uint16(imread(tiffFile));
            
        end
        
    end


end





nwb = NwbFile( ...
    'session_description', metadata.sessionDescription, ... % optional, but required by inspector
    'general_session_id', metadata.sessionID, ...
    'identifier', metadata.identifier, ...
    'session_start_time', datetime(metadata.startTime), ...
    'general_experimenter', metadata.experimenter, ... % optional
    'general_institution', metadata.institution, ... % optional, but preferred by inspector
    'general_keywords', metadata.keywords ...
);

device = types.core.Device( ...
    'description', 'Bergamo II', ...
    'manufacturer', 'ThorLabs' ...
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
    'description', 'Jackson Labs, JAX stock #006567', ... % optional, but preferred by inspector
    'species', metadata.subjectSpecies, ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', metadata.subjectSex, ...
    'strain', metadata.subjectStrain ...
);

for i = 1:nChannels
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

    channelData = types.untyped.DataPipe( ...
        'data', tiffData, ...
        'chunkSize', [1, 1, width, height] ...
    );

    image_series = types.core.TwoPhotonSeries( ...
        'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
        'starting_time', 0.0, ...
        'starting_time_rate', 0, ...
        'description', ['Two-photon series for ', channelArrays{i}], ...
        'data', channelData, ...
        'data_unit', 'microns' ...
    );
    nwb.acquisition.set(['TwoPhotonSeries', channelArrays{i}], image_series);


%     plane_segmentation = types.core.PlaneSegmentation( ...
%         'colnames', {'image_mask'}, ...
%         'description', ['Plane segmentation for ', channelArrays{i}], ...
%         'id', types.hdmf_common.ElementIdentifiers('data', int32(1:depth_or_time)), ...
%         'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
%         'image_mask', types.hdmf_common.VectorData( ...
%             'data', logical(masks.seg_img{i}), ...
%             'description', ['Image masks for ', channelArrays{i}] ...
%         ) ...
%     );
    % img_seg = types.core.ImageSegmentation();
%     img_seg.planesegmentation.set(['PlaneSegmentation', channelArrays{i}], plane_segmentation);
%     


end

ophys_module = types.core.ProcessingModule( ...
    'description',  'contains optical physiology data' ...
);
ophys_module.nwbdatainterface.set('ImageSegmentation', img_seg);
nwb.processing.set('ophys', ophys_module);
nwb.general_subject = subject;

if ~exist('nwbFilePath','var') || isempty(nwbFilePath)
    nwbFilePath = fullfile(tiffDir, name);
if ~endsWith(nwbFilePath,'.nwb')
    nwbFilePath = strcat(nwbFilePath, '.nwb');
end
end
nwbExport(nwb, nwbFilePath);

