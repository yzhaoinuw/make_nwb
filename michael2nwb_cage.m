excelFile = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\Figure1+S1\WaterIntoxication_NoPretreat_Fig.S1C-E.xlsx';
table = readcell(excelFile);
nwbPath = 'C:\Users\yzhao\Desktop\AER_Manuscript_Data\nwb_files\';

nwb = NwbFile( ...
    'general_experiment_description', '', ...
    'session_description', 'WaterIntoxication_NoPretreat_Fig.S1C-E', ... % optional, but required by inspector
    'general_session_id', 'WaterIntoxication_NoPretreat', ...
    'identifier', 'WaterIntoxication_NoPretreat', ...
    'session_start_time', datetime('1/28/2022'), ...
    ...'general_experimenter', sessionMetadata.Experimenter, ... %optional
    'general_institution', 'University of Rochester Medical Center; University of Copenhagen', ... % optional, but preferred by inspector
    'general_keywords', 'Astrocyte endfeet, glymphatic system, aquaporin-4, fluorescent microscopy, brain edema' ...
);

timestamps = 10:10:220;
% breathing scores
data = table(32, 2:23);
breathingCage1 = types.core.TimeSeries( ...
    'description', 'Breathing score - Cage 1', ...
    'data', vertcat(data{:}), ...
    'timestamps', timestamps, ...
    'data_unit', 'minute' ...
);
nwb.acquisition.set('breathingCage1', breathingCage1);

mouseID = cell2mat(table(2:21, 1));
%mouseID = reshape(mouseID', [1, 11, 20]);
cage = cell2mat(table(2:21, 2));
weight = table(2:21, 6);
dose = table(2:21, 7);
group = table(2:21, 8);
timeIP = table(2:21, 9);
notes = table(2:21, 10);

indices = types.hdmf_common.ElementIdentifiers('data', (0:19)');
 
cageTable = types.hdmf_common.DynamicTable( ...
    'description', 'an example table', ...
    'colnames', {'col1', 'col2'}, ...
    'col1', types.hdmf_common.VectorData('description', '2D char array', 'data', mouseID), ...
    'col2', types.hdmf_common.VectorData('description', '1D double array', 'data', cage), ...
    'id', indices ...  % 0-indexed, for compatibility with Python
);

nwb.scratch.set('CageInfo', cageTable);
%nwb.analysis = cageInfo;

subject = types.core.Subject( ...
    'subject_id', 'multiple', ...
    'age', 'P0D', ...
    'description', 'there are multiple mice in this file', ... % optional, but preferred by inspector
    'species', 'Mus musculus', ... % Subject species 'Mouse' should be in latin binomial form, e.g. 'Mus musculus' and 'Homo sapiens'
    'sex', 'U', ...
    'strain', '' ...
);
nwb.general_subject = subject;

nwbExport(nwb, fullfile(nwbPath, 'WaterIntoxication_NoPretreat.nwb'));