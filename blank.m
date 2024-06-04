
filename = strcat(mfilename('fullpath'), '.m');
[dirPath,name,ext] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

nwbPath = 'C:\Users\Yue\Desktop\000491\sub-21-09-20-b-act\sub-21-09-20-b-act_ses-20210920-m1_ophys.nwb';
nwb = nwbRead(nwbPath);

resolution = '(0.648, 0.648, 0.648)';
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
%nwbExport(nwb, nwbPath);