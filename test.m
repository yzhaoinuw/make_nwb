filename = strcat(mfilename('fullpath'), '.m');
[dirPath,name,ext] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

nwb = NwbFile( ...
    'session_description', 'some session', ... % optional, but required by inspector
    'general_session_id', 'test_id', ...
    'identifier', 'identifier', ...
    'session_start_time', datetime('8/19/2019  11:21:32 AM'), ...
    'general_experimenter', 'somebody', ... % optional
    'general_institution', 'KU', ... % optional, but preferred by inspector
    'general_keywords', 'keywords' ...
);

tiffPath = 'C:\Users\yzhao\Desktop\testfiles\nm190819_A1\01002.tif';
excelFileName = 'C:\Users\yzhao\Desktop\testfiles\nm190819_A1\logger1.xlsx';

tiffData = imread(tiffPath);
microscopicImage = types.core.Image( ...
    'data', tiffData, ...
    'description', 'camera 1' ...
);
images = types.core.Images( ...
    'image', microscopicImage, ...
    'description', 'images' ...
);
nwb.acquisition.set('Cam 1', images);

% xlsx logger file
table = readtable(excelFileName);
timestamps = table.TimeSinceStart_s_;
seriesNames = table.Properties.VariableNames;
pattern = '\((.*?)\)';

% skip first three columns, which are time
for k = 4:length(seriesNames)
    seriesName = char(seriesNames(k));
    sensorData = table.(seriesName);

    patternToRemove = '\s*\([^)]*\)';
    sensorName = regexprep(seriesName, patternToRemove, '');
    
    % Trim leading and trailing whitespace
    sensorName = strtrim(sensorName);
        
    patternToExtract = '\((.*?)\)';
    matches = regexp(seriesName, patternToExtract, 'tokens');
    
    % Extract the first match if it exists
    if ~isempty(matches)
        unit = matches{1}{1};
    else
        unit = '(Not available)';
    end

    timeSeries = types.core.TimeSeries( ...
    'description', sensorName, ...
    'data', sensorData, ...
    'timestamps', timestamps, ...
    'data_unit', unit ...
    );
    nwb.acquisition.set(sensorName, timeSeries);
end

nwbExport(nwb, 'felixTest.nwb');