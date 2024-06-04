addpath 'abfload'
filename = strcat(mfilename('fullpath'), '.m');
[dirPath,name,ext] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))


abfFileName = 'C:\Users\yzhao\Desktop\testfiles\FB2352\23816001.abf';
[d,si,h] = abfload(abfFileName);
% si: sampling interval

%%
tiffPath = 'C:\Users\yzhao\Desktop\testfiles\FB2352\01_FB2352_GeNL_2x_300x_bin1_1_MMStack_Default.ome.tif';
tiffData = imread(tiffPath);

nwb = NwbFile( ...
    'session_description', 'some session', ... % optional, but required by inspector
    'general_session_id', 'test_id', ...
    'identifier', 'identifier', ...
    'session_start_time', datetime('8/19/2019  11:21:32 AM'), ...
    'general_experimenter', 'somebody', ... % optional
    'general_institution', 'KU', ... % optional, but preferred by inspector
    'general_keywords', 'keywords' ...
);

microscopicImage = types.core.Image( ...
    'data', tiffData, ...
    'description', 'camera 1' ...
);

for i = 1:h.nADCNumChannels
    clampSeries = types.core.TimeSeries( ...
        'description', ['clamp ' num2str(i)], ...
        'data', d(:, i), ...
        'starting_time', h.recTime(1), ...
        'starting_time_rate', si, ...
        'data_unit', h.recChUnits{i} ...
    );
    nwb.acquisition.set(['clamp' num2str(i)], clampSeries);
end

images = types.core.Images( ...
    'image', microscopicImage, ...
    'description', 'images' ...
);
nwb.acquisition.set('Cam 1', images);
%nwbExport(nwb, 'felixClampTest.nwb');
