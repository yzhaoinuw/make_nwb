function felix2nwb(folderPath, writePath, varargin)

[~, sessionName, ~] = fileparts(folderPath);

if nargin > 2
    parentSession = varargin{1};
    sessionName = [parentSession '_' sessionName];
end

nwbPath = fullfile(writePath, [sessionName '.nwb']);

session = dir(folderPath);
% remove all files (isdir property is 0)
subsessions = session([session(:).isdir]);
% remove '.' and '..' 
subsessions = subsessions(~ismember({subsessions(:).name},{'.','..'}));
if ~isempty(subsessions)
    for i = 1:length(subsessions)
        subsessionName = subsessions(i).name;
        subfolderPath = fullfile(folderPath, subsessionName);
        % apply recursion
        felix2nwb(subfolderPath, writePath, sessionName)
        continue
    end

elseif isfile(nwbPath)
   
else
    metadataFile = 'C:\Users\yzhao\Desktop\metadata_felix.json'; % filename in JSON extension 
    str = fileread(metadataFile); % dedicated for reading files as text 
    metadata = jsondecode(str);
    
    sessionMetadata = metadata.(sessionName);
    
    % initiate nwb
    nwb = NwbFile( ...
        'general_experiment_description', 'GeNL bioluminescence imaging detects the existence of spontaneous transient "hypoxic pockets" in awake behaving mice.', ...
        'session_description', sessionMetadata.sessionDescription, ... % optional, but required by inspector
        'general_session_id', sessionName, ...
        'identifier', sessionName, ...
        'session_start_time', datetime(sessionMetadata.DateOfExperiment, 'InputFormat','MM-dd-yyyy'), ...
        'general_experimenter', sessionMetadata.Experimenter, ... % optional
        'general_institution', sessionMetadata.Institution, ... % optional, but preferred by inspector
        'general_keywords', sessionMetadata.Keyword ...
    );
    
    
    % subject info
    ageWeeks = sessionMetadata.Age_weeks_;
    ageWeeks = ['P' num2str(ageWeeks) 'W'];
    subject = types.core.Subject( ...
        'subject_id', sessionMetadata.SubjectID, ...
        'age', ageWeeks, ...
        'description', ['Genotype: ' sessionMetadata.Genotype], ... % optional, but preferred by inspector
        'species', 'Mus musculus', ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
        'sex', upper(sessionMetadata.Gender), ...
        'strain', sessionMetadata.Strain ...
    );
    nwb.general_subject = subject;
    
    
    % add abf
    abfFiles = dir(fullfile(folderPath, '*.abf'));
    
    % Loop through the files and print their names
    for k = 1:length(abfFiles)
        %disp(abfFiles(k).name);
        abfFile = fullfile(folderPath, abfFiles(k).name);
        [d,si,h] = abfload(abfFile);
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
    end
    
    
    % add xlsx logger
    % xlsx logger file
    % add tiff
    xlsxFiles = dir(fullfile(folderPath, '*.xlsx'));
    
    % Loop through the files and print their names
    for j = 1:length(xlsxFiles)
        xlsxName = xlsxFiles(j).name;
        %disp(xlsxName);
        xlsxFile = fullfile(folderPath, xlsxName);
        table = readtable(xlsxFile);
        timestamps = table.TimeSinceStart_s_;
        seriesNames = table.Properties.VariableNames;
        
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
    end
    
    
    % add tiff
    tiffFiles = dir(fullfile(folderPath, '*.tif'));
    
    % Loop through the files and print their names
    for j = 1:length(tiffFiles)
        tiffName = tiffFiles(j).name;
        %disp(tiffName);
        tiffFile = fullfile(folderPath, tiffName);
        tiffInfo = imfinfo(tiffFile);
        numFrames = numel(tiffInfo);
        tiffHeight = tiffInfo(1).Height;
        tiffWidth = tiffInfo(1).Width;
        tiffRawData = zeros(tiffHeight, tiffWidth, numFrames, 'uint16');  % Change 'uint16' to the appropriate type
        
        for k = 1:numFrames
            tiffRawData(:, :, k) = imread(tiffFile, 'Index', k);
        end
        
        tiffData = types.untyped.DataPipe( ...
            'data', permute(tiffRawData, [3,1,2]), .....
            'chunkSize', [1, tiffHeight, tiffWidth] ...
        );
        
        comments = [ ...
            'Resolution: ' num2str(sessionMetadata.PixelsizeUm_pixel) ' um/pixel; ' ...
            'Condition: ' sessionMetadata.Condition '; ' ...
            'Drug ID: ' sessionMetadata.DrugID '; ' ...
            'Promoter: ' sessionMetadata.Promoter ';' ...
        ];
    
        imageSeries = types.core.ImageSeries( ...
            'data', tiffData, ...
            'description', tiffName, ...
            'data_unit', 'um', ...
            'starting_time', 0, ...
            'starting_time_rate', sessionMetadata.SampleF, ...
            'comments', comments ...
        );
        nwb.acquisition.set(tiffName, imageSeries);
    end
    
    
    % add png
    % initiate image collections
    
    
    pngFiles = dir(fullfile(folderPath, '*.png'));
    if ~isempty(pngFiles)
        pngImages = types.core.Images( ...
        'description', 'static images' ...
        );
    
        % Loop through the files and print their names
        for k = 1:length(pngFiles)
            pngName = pngFiles(k).name;
            %disp(pngName);
            pngFile = fullfile(folderPath, pngName);
            %pngInfo = imfinfo(pngFile);
            %pngHeight = pngInfo(1).Height;
            %pngWidth = pngInfo(1).Width;
            pngRawData = imread(pngFile);
            
            image = types.core.Image( ...
                'data', permute(pngRawData, [3,1,2]), ...
                'resolution', sessionMetadata.PixelsizePixels_cm, ...
                'description', pngName ...
            );
            
            pngImages.image.set(pngName, image);
        end
        nwb.acquisition.set('png_images', pngImages);
    end
    
    nwbExport(nwb, nwbPath);
end
end