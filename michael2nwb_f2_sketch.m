addpath("./ReadImageJROI")

sliceImagesPath = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure2\SliceImages';
sliceROIsPath = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure2\SliceROIs';
sliceSubregionAnalysisROIsPath = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure2\SliceSubregionAnalysisROIs';
wholeBrainImagesPath = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure2\WholeBrainImages';
wholeBrainROIsPath = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure2\WholeBrainROIs';


roiFile = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure2\SliceROIs\220706_01\01_01.roi';
[sROI] = ReadImageJROI(roiFile);
subjectID = '220706_01';
% Define your directory and prefix
prefix = strrep(subjectID,'_','-');

% Use a wildcard pattern: prefix*
sliceImageFileDir = dir(fullfile(sliceImagesPath, [prefix, '*']));

% If you want just the filenames as a cell array:
fullPaths = fullfile({sliceImageFileDir.folder}, {sliceImageFileDir.name});

