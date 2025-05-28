str = 'Sensor 1 - O2 (mmHg)';

% Regular expression to find and remove text inside parentheses (including the parentheses)
patternToRemove = '\s*\([^)]*\)';
cleanedStr = regexprep(str, patternToRemove, '');

% Trim leading and trailing whitespace
cleanedStr = strtrim(cleanedStr);

disp(['Cleaned string: ', cleanedStr]);

% Regular expression to match text inside parentheses
patternToExtract = '\((.*?)\)';

% Use regexp to find matches for extraction
matches = regexp(str, patternToExtract, 'tokens');

% Extract the first match if it exists
if ~isempty(matches)
    extractedString = matches{1}{1};
else
    extractedString = '';
end

disp(['Extracted string: ', extractedString]);
