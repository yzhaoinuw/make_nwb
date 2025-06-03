addpath("npy-matlab/")
addpath('/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/make_nwb/matnwb')
addpath('/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/make_nwb/ReadImageJROI')

figName = '2P_cAMP_Calcium';
figPath = ['/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Marta2/' figName];

%roiFile = '/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Marta2/2P_cAMP_Calcium/PF_GCaMP1_bPAC_region1/ROI#2.npy';
%tifFile = '/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Marta2/2P_cAMP_Calcium/PF_GCaMP1_bPAC_region1/ChanA_stk.tif';
%tifInfo = imfinfo(tifFile);
%tidData = imread(tifFile, 1);
writePath = ['/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/marta_nwb/' figName];

figDir = dir(figPath);
sessionFolders = figDir([figDir.isdir] & ~ismember({figDir.name}, {'.', '..'}));
metadataFile = fullfile('/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/marta_nwb', [figName '.xlsx']);
metadata = readtable(metadataFile);
metadata.Properties.RowNames = string(metadata{:,1});
metadata.Starting_time = datetime(metadata.Starting_time, 'ConvertFrom', 'excel');
metadata.Starting_time.Year = 2024;
metadata.Starting_time.Month = 9;
metadata.Starting_time.Day = 1;
metadata(:, 1) = [];

for l=1:numel(sessionFolders)
sessionID = sessionFolders(l).name;
%sessionID = '20230111_1_bPAC_KX_ROI1_LED1s';
nwbFilePath = fullfile(writePath, [sessionID '.nwb']);
if exist(nwbFilePath, 'file')
    continue
end
disp(['processing ' sessionID '.'])

startTime = metadata(sessionID, :).Starting_time;
deviceDescription = metadata{sessionID, 'Device'}{:};
emissionLambda = metadata{sessionID, 'Emission_lambda'};
excitationLambda = metadata{sessionID, 'Excitation_lambda'};
imagingRate = metadata{sessionID, 'Imaging_rate'};
location = metadata{sessionID, 'Location'}{:};
indicator = metadata{sessionID, 'Indicator'}{:};
startingTimeRate = metadata{sessionID, 'Starting_time_rate'};
subjectID = metadata{sessionID, 'subject_id'}{:};
species = 'Mus musculus';
sex = metadata{sessionID, 'sex'}{:};
ageWeeks = metadata{sessionID, 'age'}{:};
ageWeeks = str2double(ageWeeks(1:end-3));
subjectStrain = metadata{sessionID, 'Strain'}{:};

nwb = NwbFile( ...
    'session_description', 'figName', ... % optional, but required by inspector
    'general_experiment_description', 'one-photon imaging', ...
    'general_session_id', sessionID, ...
    'identifier', [figName '_' sessionID], ...
    'session_start_time', startTime, ...
    'general_experimenter', 'Vittani, Marta', ... % optional
    'general_institution', 'University of Copenhagen', ... % optional, but preferred by inspector
    'general_keywords', 'neurovascular coupling, optogenetic GPCR, cAMP elevation, blood flow, cortex, mouse, optical imaging.' ...
);

% subject info
ageWeeks = 'P' + string(ageWeeks) + 'W';
subject = types.core.Subject( ...
    'subject_id', subjectID, ...
    'age', char(ageWeeks), ...
    'description', subjectStrain, ... % optional, but preferred by inspector
    'species', species, ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', sex, ...
    'strain', subjectStrain ...
);
nwb.general_subject = subject;

device = types.core.Device( ...
    'description', deviceDescription, ...
    'manufacturer', 'n/a' ...
);
nwb.general_devices.set('Device', device);

optical_channel = types.core.OpticalChannel( ...
    'description', 'RG channels. 607/70 for R(A), 525/50 for G(B)', ...
    'emission_lambda', emissionLambda ...
);
imaging_plane = types.core.ImagingPlane( ...
    'optical_channel', optical_channel, ...
    'description', 'Imaging plane', ...
    'device', types.untyped.SoftLink(device), ...
    'excitation_lambda', excitationLambda, ...
    'imaging_rate', imagingRate, ...
    'indicator', indicator, ...
    'location', location, ...
    'grid_spacing_unit', 'arbitrary unit' ...
);
nwb.general_optophysiology.set('ImagingPlane', imaging_plane);

%% read tif
tifFiles = dir(fullfile(figPath, sessionID, '*.tif'));
for i = 1:numel(tifFiles)
tifFile = fullfile(tifFiles(i).folder, tifFiles(i).name);
[~, tifName, ~] = fileparts(tifFiles(i).name);
disp(tifFiles(i).name)
%tifFile = '/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Marta1/fig_1_pf_kx/20240409_1_bPAC_KX_LED1s/20240409_1_bPAC_KX_LED1s.tif';
%tifFile = fullfile(figPath, sessionID, 'm1_ROI1_LED1s.tif');
tifInfo = imfinfo(tifFile);
nFrames = max(numel(tifInfo), 2);
height = tifInfo(1).Height;
width = tifInfo(1).Width;

tifData = zeros(height, width, nFrames, 'uint16');
for j = 1:numel(tifInfo)
    tifData(:, :, j) = imread(tifFile, j);
end
onePhotonData = types.untyped.DataPipe( ...
    'data', tifData, ...
    'chunkSize', [height, width, 10] ...
);
imageSeries = types.core.OnePhotonSeries( ...
    'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
    'starting_time', 0.0, ...
    'starting_time_rate', startingTimeRate, ...
    'description', ['One-photon series- ' tifName], ...
    'data', onePhotonData, ...
    'data_unit', 'arbitrary unit' ...
);
nwb.acquisition.set(['OnePhotonSeries-' tifName], imageSeries);
end
%% read ROI

roiFiles = dir(fullfile(figPath, sessionID, '*.npy'));
nROI = numel(roiFiles);

roiMasks = {};
pixelMaskIndex = zeros(nROI, 1);
for k = 1:nROI
roiFile = fullfile(roiFiles(k).folder, roiFiles(k).name);
[~, roiName, ~] = fileparts(roiFiles(k).name);
disp(roiFiles(k).name)

roi = readNPY(roiFile);
roiMasks{k} = roi;
pixelMaskIndex(k) = size(roi, 1);
end

pixelMaskIndex = cumsum(pixelMaskIndex);
roiMasks = vertcat(roiMasks{:});

pixelMaskStruct = struct();
pixelMaskStruct.x = uint32(round(roiMasks(:, 1)));
pixelMaskStruct.y = uint32(round(roiMasks(:, 2)));
pixelMaskStruct.weight = single(ones(size(roiMasks, 1), 1));
pixelMaskTable = struct2table(pixelMaskStruct);

pixelMasks = types.hdmf_common.VectorData(...
    'data', pixelMaskTable, ...
    'description', 'ROI pixel position (x, y) and pixel weight' ...
);

pixelMaskIndex = types.hdmf_common.VectorIndex(...
    'data', pixelMaskIndex, ...
    'description', 'Index into pixel_mask VectorData', ...
    'target', types.untyped.ObjectView(pixelMasks) ...
);

planeSegmentation = types.core.PlaneSegmentation( ...
    'colnames', {'pixel_mask'}, ...
    'description', 'Plane segmentation', ...
    ...'id', types.hdmf_common.ElementIdentifiers('data', 1:k), ...
    'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
    'pixel_mask_index', pixelMaskIndex, ...
    'pixel_mask', pixelMasks ...
);
imgSeg = types.core.ImageSegmentation();
imgSeg.planesegmentation.set('PlaneSegmentation', planeSegmentation);
ophysModule = types.core.ProcessingModule( ...
    'description',  'Contains one-photon ROI data' ...
);
ophysModule.nwbdatainterface.set('ImageSegmentation', imgSeg);
nwb.processing.set('ophys', ophysModule);
%%

nwbExport(nwb, nwbFilePath);
end