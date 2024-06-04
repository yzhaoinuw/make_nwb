addpath('./matnwb')

slicePath = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure2\SliceImages'; % Replace with your directory path
wholeBrainPath = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure2\WholeBrainImages';
mousID = '220706-01_'; % Files should start with this prefix

% Get a list of all files and folders in the directory
wholeBrainDir = dir(wholeBrainPath);
% Filter to include only files (omit directories)
wholeBrainTiffs = wholeBrainDir(~[wholeBrainDir.isdir]);

% Check each file to see if it starts with the specified prefix
imageCollection = types.core.Images( ...
    'description', 'Brain images'...
);
for i = 1:length(wholeBrainTiffs)
    file = wholeBrainTiffs(i).name;
    if startsWith(file, mousID) && endsWith(file, ".TIF")
        [~, name, ~] = fileparts(file);
        disp(file)
        tiffFile = fullfile(wholeBrainPath, file);
        imageArray = imread(tiffFile);
        image = types.core.GrayscaleImage( ...
            'data', imageArray, ...  % required
            ...'resolution', 70.0, ...
            'description', name ...
        );
        imageCollection.image.set(['WholeBrainImage' i], image);
    end
end

%%
% Get a list of all files and folders in the directory
sliceDir = dir(slicePath);
% Filter to include only files (omit directories)
sliceTiffs = sliceDir(~[sliceDir.isdir]);

% Check each file to see if it starts with the specified prefix
for i = 1:length(sliceTiffs)
    file = sliceTiffs(i).name;
    if startsWith(file, mousID) && endsWith(file, ".TIF")
        disp(file)
        [~, name, ~] = fileparts(file);
        tiffFile = fullfile(slicePath, file);
        %matchingFiles{end+1} = filename; % Add to the list of matching files
        imageArray = imread(tiffFile);
        image = types.core.GrayscaleImage( ...
            'data', imageArray, ...  % required
            ...'resolution', 70.0, ...
            'description', name ...
        );
        imageCollection.image.set(['SliceImage' i], image);
    end
end