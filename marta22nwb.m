addpath('/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/make_nwb/matnwb')
addpath('/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/make_nwb/ReadImageJROI')

figName = 'figS4y_RCaMP3_bPAC_brain_slices';
figPath = ['/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Marta2/' figName];
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
    'description', 'grayscale', ...
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
nwb.acquisition.set(['OnePhotonSeries' tifName], imageSeries);
end

%% read roi
roiFiles = dir(fullfile(figPath, sessionID, '*.roi'));
if numel(roiFiles) > 0
    nROI = max(numel(roiFiles), 2);
    roiMasks = false(height, width, nROI);

for k = 1:numel(roiFiles)
roiFile = fullfile(roiFiles(k).folder, roiFiles(k).name);
[~, roiName, ~] = fileparts(roiFiles(k).name);
disp(roiFiles(k).name)
%roiName = 'm1_ROI1_LED1s_kymo1';
%roiFile = fullfile(figPath, sessionID, 'm1_ROI1_LED1s_kymo1.roi');
[sROI] = ReadImageJROI(roiFile);
roiRect = sROI.vnRectBounds;
y0 = roiRect(1);
x0 = roiRect(2);
y1 = roiRect(3);
x1 = roiRect(4);
roiMask = false(height, width);
roiMask(y0:y1, x0:x1) = true;
roiMasks(:, :, k) = roiMask;
end

planeSegmentation = types.core.PlaneSegmentation( ...
    'colnames', {'image_mask'}, ...
    'description', 'Plane segmentation', ...
    ...'id', types.hdmf_common.ElementIdentifiers('data', 1:k), ...
    'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
    'image_mask', types.hdmf_common.VectorData( ...
        'data', roiMasks, ...
        'description', [num2str(numel(roiFiles)) ' image masks'] ...
    ) ...
);
imgSeg = types.core.ImageSegmentation();
imgSeg.planesegmentation.set('PlaneSegmentation', planeSegmentation);
ophysModule = types.core.ProcessingModule( ...
    'description',  'Contains one-photon ROI data' ...
);
ophysModule.nwbdatainterface.set('ImageSegmentation', imgSeg);
nwb.processing.set('ophys', ophysModule);
end

%%
nwbExport(nwb, nwbFilePath);
end