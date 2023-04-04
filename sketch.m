tiffDir = '.\brainwaveZZZ\z-stack-up\';

filename = strcat(mfilename('fullpath'), '.m');
[dirPath,~,~] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

xmlFile = fullfile(tiffDir, 'Experiment.xml');

info = read_Thor_xml(xmlFile);

time = datetime(info.Date.date);
name = info.Name;
%nChannels = info.NumCh;
nChannels = 2;
channelArrays = {'ChanA', 'ChanB', 'ChanC'};
channelNames = channelArrays{1:nChannels};
channelFiles = strings(1, nChannels);

for i = 1:nChannels
    channelFiles(i) = fullfile(tiffDir, [channelNames,'_0001_0001_',num2str(i,'%04d') '_0001.tif']);
end

%depth = experiment.NumIm; 
depth = 10;
%tiffData = zeros(nChannels, 512, 512, depth);
tiffData = NaN(3, 512, 512, depth);
for i = 1:depth
    if mod(i,100) == 0
        disp(['Importing image ' num2str(i) ' of ' num2str(depth)])
    end

    for j = 1:nChannels
        tiffData(j, :, :, i) = uint16(imread(channelFiles(j)));
    end

end

for i = 1:depth
rgbImage = types.core.RGBImage( ...
    'data', tiffData(:, :, :, i), ...  % required
    ...'resolution', 70.0, ...
    'description', ['depth_', num2str(i)] ...
);
imageCollection = types.core.Images( ...
    'description', 'Images at various depths.'...
);
imageCollection.image.set('Image', rgbImage);
end

