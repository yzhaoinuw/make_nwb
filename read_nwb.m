
filename = strcat(mfilename('fullpath'), '.m');
[dirPath,name,ext] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

nwbPath = 'C:\Users\Yue\Desktop\000491\sub-21-09-20-b-act\sub-21-09-20-b-act_ses-20210920-m1_ophys.nwb';
nwb = nwbRead(nwbPath);

tiffDir = '.\brainwaveZZZ\ati-zstack-x4-512\';
resultsFile = fullfile(tiffDir, 'Results.mat');
results = load(resultsFile);

img_seg = results.seg_img{3};
shape = size(img_seg);
depth = shape(3);
imaging_plane = nwb.general_optophysiology.get('imaging_plane1');
plane_segmentation = types.core.PlaneSegmentation( ...
        'colnames', {'image_mask'}, ...
        'description', ['Plane segmentation for ', 'ChanC'], ...
        'id', types.hdmf_common.ElementIdentifiers('data', int32(1:depth)), ...
        'imaging_plane', types.untyped.SoftLink(imaging_plane), ...
        'image_mask', types.hdmf_common.VectorData( ...
            'data', logical(img_seg), ...
            'description', ['Image masks for ', 'ChanC'] ...
        ) ...
    );

nwb.processing.get('ophys').nwbdatainterface.get('ImageSegmentation').planesegmentation.set(['PlaneSegmentation', 'ChanC'], plane_segmentation);

% experiment description
addExpDescription = "Additional details regarding the subjects, tracer injection, image acquisition, " + ...
    "and segmentation can be found in the manuscript at https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9949243/";
prevExpDescription = nwb.general_experiment_description;
nwb.general_experiment_description = char(prevExpDescription + " " + addExpDescription);

% session description
sessionDescription = nwb.session_description;
addSessionDescription = " (series of 2D microscopy images acquired with focal planes at various cortical depths separated by 1 micron)";
wordToFind = "Zstack";
nwb.session_description = char(insertAfter(sessionDescription, wordToFind, addSessionDescription));

resolution = '(0.334, 0.334, 0.334)';

% ImagingPlane
try
    %resolution
    nwb.general_optophysiology.get('imaging_plane1').reference_frame = resolution;
    % units
    nwb.general_optophysiology.get('imaging_plane1').origin_coords_unit = 'microns';
    nwb.general_optophysiology.get('imaging_plane1').grid_spacing_unit = 'microns';
catch
    a = 0;
end

try
    %resolution
    nwb.general_optophysiology.get('imaging_plane2').reference_frame = resolution;
    % units
    nwb.general_optophysiology.get('imaging_plane2').origin_coords_unit = 'microns';
    nwb.general_optophysiology.get('imaging_plane2').grid_spacing_unit = 'microns';
catch
    a = 0;
end

try
    %resolution
    nwb.general_optophysiology.get('imaging_plane3').reference_frame = resolution;
    % units
    nwb.general_optophysiology.get('imaging_plane3').origin_coords_unit = 'microns';
    nwb.general_optophysiology.get('imaging_plane3').grid_spacing_unit = 'microns';
catch
    a = 0;
end

% imaging data
try
    nwb.acquisition.get('TwoPhotonSeriesChanA').description = char("Two-photon series for Green fluorescent protein.");
catch
    a = 0;
end

try
    nwb.acquisition.get('TwoPhotonSeriesChanB').description = char("Two-photon series for Alexa Fluor594/647 (tracer in PVS).");
catch
    a = 0;
end

try
    nwb.acquisition.get('TwoPhotonSeriesChanC').description = char("Two-photon series for Alexa Fluor594/647 (tracer in PVS).");
catch
    a = 0;
end


% segmentation masks
try
    nwb.processing.get('ophys').nwbdatainterface.get('ImageSegmentation').planesegmentation...
    .get('PlaneSegmentationChanA').image_mask.description = char('Segmentation masks for blood vessel.');
catch
    a = 0;
end

try
    nwb.processing.get('ophys').nwbdatainterface.get('ImageSegmentation').planesegmentation...
    .get('PlaneSegmentationChanB').image_mask.description = char('Segmentation masks for ChanB.');
catch
    a = 0;
end

try
    nwb.processing.get('ophys').nwbdatainterface.get('ImageSegmentation').planesegmentation...
    .get('PlaneSegmentationChanC').image_mask.description = char('Segmentation masks for perivascular space.');
catch
    a = 0;
end

nwbExport(nwb, nwbPath);

