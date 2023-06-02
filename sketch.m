clear;

tiffDir = '.\brainwaveZZZ\z-stack-down\';
filename = strcat(mfilename('fullpath'), '.m');
[dirPath,~,~] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

maskFile = fullfile(tiffDir, 'Results.mat');
xmlFile = fullfile(tiffDir, 'Experiment.xml');

masks = load(maskFile);
info = read_Thor_xml(xmlFile);
experiment = readExperiment(xmlFile);

if ~exist('metadataFile','var') || isempty(metadataFile)
    metadataFile = fullfile(tiffDir, 'metadata.json');
end

assert(isfile(metadataFile), 'metadata.json not found. please use the metadata wizard to create one.')
metadata = jsondecode(fileread(metadataFile));

time = datetime(metadata.startTime);
name = info.Name;
frameRate = info.FrameRate;
nChannels = info.NumCh;
width = info.ImageWidth
height = info.ImageHeight
channelArrays = {'ChanA', 'ChanB', 'ChanC'};
emmisionArrays = {698, 607, 525};
indicatorArrays = {'GFP', 'GFP', 'beta-Act-GFP'};
depth = experiment.NumIm;

tiffData = zeros(nChannels, width, height, depth);
for i = 1:nChannels
    for j = 1:depth
        if mod(j, 100) == 0
            disp(['Importing image ' num2str(j) ' of ' num2str(depth)])
        end
        tiffFile = fullfile(tiffDir, [channelArrays{i}, '_0001_0001_', num2str(j,'%04d'), '_0001.tif']);
        tiffData(i, :, :, j) = uint16(imread(tiffFile));
    end

end

nwb = NwbFile( ...
    'session_description', metadata.description, ... % optional, but required by inspector
    'general_experiment_description', [ ...
        'This data is labeled as location C in the 2023 manuscript, ' ...
        'Sizes and Shapes of Perivascular Spaces Surrounding Murine Pial Arteries  by Raicevic et al' ...
        'Additional details regarding the subjects, tracer injection, image acquisition,' ...
        'and segmentation can be found in the manuscript at https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9949243/'
    ], ...
    'general_session_id', metadata.sessionID, ...
    'identifier', metadata.identifier, ...
    'session_start_time', datetime(metadata.startTime), ...
    'general_experimenter', [metadata.lastName ', ' metadata.firstName], ... % optional
    'general_institution', metadata.institution, ... % optional, but preferred by inspector
    'general_keywords', metadata.keywords ...
);

device = types.core.Device( ...
    'description', 'Bergamo II', ...
    'manufacturer', 'ThorLabs' ...
);
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
        'emission_lambda', emmisionArrays{i} ...
    );
    imaging_plane_name = ['imaging_plane', num2str(i)];
    imaging_plane = types.core.ImagingPlane( ...
        'optical_channel', optical_channel, ...
        'description', ['Imaging plane for ', channelArrays{i}], ...
        'device', types.untyped.SoftLink(device), ...
        'excitation_lambda', 890., ...
        'imaging_rate', frameRate, ...
        'indicator', indicatorArrays{i}, ...
        'location', 'On the middle cerebral artery, 5-7 bifurcations distal to its start', ...
        'grid_spacing_unit', 'arbitrary unit' ...
    );
    nwb.general_optophysiology.set(imaging_plane_name, imaging_plane);

    channelData = types.untyped.DataPipe( ...
        'data', tiffData(i, :, :, :), ...
        'chunkSize', [1, width, height, 1] ...
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

