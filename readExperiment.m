function [Experiment] = readExperiment(xmlFile)
%READEXPERIMENT Reads pertinent data from Experiment.xml into a structure
%   DataPath: path to the location of Experiment.xml
% this plays a role similar to read_Thor_xml, but it works better for reading in info
% about z-stacks. Someday I ought to combine them. When doing so, refer to
% read_tiff to see what exactly readExperiment does better (I think maybe
% it detects whether it's a z-stack or t-stack and names thing
% accordingly. I can't remember if there are other important differnces). 

Experiment = xml2struct(xmlFile);
Experiment.pixelSizeUM=str2double(Experiment.ThorImageExperiment.LSM.Attributes.pixelSizeUM);
Experiment.stepSizeUM=str2double(Experiment.ThorImageExperiment.ZStage.Attributes.stepSizeUM);
Experiment.frameRate=str2double(Experiment.ThorImageExperiment.LSM.Attributes.frameRate);
Experiment.heightUM=str2double(Experiment.ThorImageExperiment.LSM.Attributes.heightUM);
Experiment.widthUM=str2double(Experiment.ThorImageExperiment.LSM.Attributes.widthUM);
Experiment.pixelX=str2double(Experiment.ThorImageExperiment.LSM.Attributes.pixelX);
Experiment.pixelY=str2double(Experiment.ThorImageExperiment.LSM.Attributes.pixelY);
Experiment.NumZ=str2double(Experiment.ThorImageExperiment.ZStage.Attributes.steps);
Experiment.NumT=str2double(Experiment.ThorImageExperiment.Timelapse.Attributes.timepoints);
disp(['XY res: ' num2str(Experiment.pixelSizeUM)])
if Experiment.NumZ>1
    disp(['Z res: ' num2str(Experiment.stepSizeUM)])
    Experiment.NumIm=Experiment.NumZ;
else
    disp(['frameRate: ' num2str(Experiment.frameRate)])
    Experiment.NumIm=Experiment.NumT;
end
disp(['Num Images: ' num2str(Experiment.NumIm)])

coords=struct;
coords.X=(0:Experiment.pixelX-1)*Experiment.pixelSizeUM;
coords.X_unit='microns';
coords.Y=(0:Experiment.pixelY-1)*Experiment.pixelSizeUM;
coords.Y_unit='microns';
if Experiment.NumZ>1
    coords.Z=(0:Experiment.NumZ)*Experiment.stepSizeUM; % I have no idea why NumZ is one less than the recorded frames.
%     coords.Z=coords.Z(frlist);
    coords.Z_unit='microns';
    coords.S=coords.Z;
else
    coords.T=(0:Experiment.NumT-1)/Experiment.frameRate;
%     coords.T=coords.T(frlist);
    coords.T_unit='seconds';
    coords.S=coords.T;
end

Experiment.coords=coords;



end

