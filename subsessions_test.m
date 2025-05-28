folderPath = 'C:\Users\yzhao\Desktop\testfiles\';
writePath = 'C:\Users\yzhao\Desktop\testfiles\';


folder = dir(folderPath);
% remove all files (isdir property is 0)
sessions = folder([folder(:).isdir]);
% remove '.' and '..' 
sessions = sessions(~ismember({sessions(:).name},{'.','..'}));
for i = 1:numel(sessions)
    sessionPath = fullfile(folderPath, sessions(i).name);
    disp(sessionPath)
    felix2nwb(sessionPath, writePath)
end