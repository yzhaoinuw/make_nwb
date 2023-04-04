metadata = struct;

prompt = "Enter experimenter last name: ";
metadata.lastName = input(prompt, 's');

prompt = "Enter experimenter first name: ";
metadata.firstName = input(prompt, 's');

prompt = "Enter session ID: ";
metadata.generalSessionId = input(prompt, 's');

prompt = "Enter session start time in this format (yyyy-MM-dd HH:mm:ss): ";
dateParsed = false;
while ~dateParsed
    try
        metadata.sessionStartTime = datetime(input(prompt, 's'),'Format','yyyy-MM-dd HH:mm:ss');
        dateParsed = true;
    catch ME
        fprintf('Error: %s\n', ME.message);
    end
end

prompt = "Enter experiment description: ";
metadata.experimentDescription = input(prompt, 's');

prompt = "Enter subject ID: ";
metadata.subjectID = input(prompt, 's');

prompt = "Enter subject species (default is Mouse): ";
metadata.subjectSpecies = input(prompt, 's');
if isempty(metadata.subjectSpecies)
    metadata.subjectSpecies = 'Mus musculus';
end

prompt = "Enter subject sex: ";
metadata.subjectSex = input(prompt, 's');

prompt = "Enter subject strain: ";
metadata.subjectStrain = input(prompt, 's');

prompt = "Enter subject age: ";
metadata.subjectAge = input(prompt, 's');

% Step 2: Convert the MATLAB structure to a JSON formatted string
jsonString = jsonencode(metadata);

% Step 3: Open a file for writing
filename = 'metadata.json';
fileID = fopen(filename, 'w');

% Step 4: Write the JSON string to the file
fprintf(fileID, jsonString);

% Step 5: Close the file
fclose(fileID);
