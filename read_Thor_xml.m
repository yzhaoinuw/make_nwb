function data = read_Thor_xml(fname)
% Usage: data = read_Thor_xml(fname)
% Given file "fname" created by a ThorLabs microscope, read_Thor_xml reads
% the file and returns a struct array "data" containing metadata about the
% recording, including image width, image height, frame count, frame rate,
% bit depth, and spatial resolution. Requires xml2struct.m from Matlab File
% Exchange. 

% Written 1 December 2018 by Rebeca Toro. 
% Updated 3 October 2019 by Doug Kelley for niceties. Also renamed
% read_Thor_xml.m. 
% Updated 13 January 2020 by Doug Kelley to fail gracefully if fields are
% unavailable (try/catch) and read more of the metadata.  
% Updated 15 April 2021: Including HorizontalFlip, VerticalFlip, and
% isLineScan.

if nargin<1
    error(['Usage: data = ' mfilename '(fname)'])
end

s=xml2struct(fname); % use function from file exchange 

data=struct;
try
    data.Name = s.ThorImageExperiment.Name.Attributes.name;
catch
    data.Name = [];
end
try
    data.Date = s.ThorImageExperiment.Date.Attributes;
catch
    data.Date = [];
end
try
    data.ThorImageVersion = ...
        s.ThorImageExperiment.Software.Attributes.version;
catch
    data.ThorImageVersion = [];
end
try
    data.Magnification = str2double( ...
        s.ThorImageExperiment.Magnification.Attributes.mag );
catch
    data.Magnification = [];
end
try
    data.ExperimentNotes = ...
        s.ThorImageExperiment.ExperimentNotes.Attributes.text;
catch
    data.ExperimentNotes = [];
end
try
    data.Comments = s.ThorImageExperiment.Comments.Attributes.text;
catch
    data.Comments = [];
end
try
    data.AllocatedFrames = str2double( ...
        s.ThorImageExperiment.Streaming.Attributes.frames );
catch
    data.AllocatedFrames = [];
end
try
    if str2double(s.ThorImageExperiment.PowerRegulator.Attributes.enable)
        data.PowerRegulator = ...
            s.ThorImageExperiment.PowerRegulator.Attributes.path;
    else
        data.PowerRegulator = [];
    end
catch
    data.PowerRegulator = [];
end
try
    data.FrameRate = str2double( ...
        s.ThorImageExperiment.LSM.Attributes.frameRate );
catch
    data.FrameRate = [];
end
try
    data.umperpix = str2double( ...
        s.ThorImageExperiment.LSM.Attributes.pixelSizeUM );
catch
    data.umperpix = [];
end
try
    data.stepSizeUM = str2double( ...
        s.ThorImageExperiment.ZStage.Attributes.stepSizeUM );
catch
    data.stepSizeUm = [];
end
try
    data.ImageBitDepthReal = str2double( ...
        s.ThorImageExperiment.LSM.Attributes.inputRange1 );
catch
    data.ImageBitDepthReal = [];
end
try
    data.ImageHeight = str2double( ...
        s.ThorImageExperiment.LSM.Attributes.pixelY );
catch
    data.ImageHeight = [];
end
try
    data.ImageWidth =  str2double( ...
        s.ThorImageExperiment.LSM.Attributes.pixelX );
catch
    data.ImageWidth = [];
end
try
    data.BitsPerPixel = str2double( ...
        s.ThorImageExperiment.Camera.Attributes.bitsPerPixel );
catch
    data.BitsPerPixel = [];
end
try
    data.NumCh = numel( ...
        s.ThorImageExperiment.Wavelengths.Wavelength );
catch
    data.NumCh = [];
end
try
    data.HorizontalFlip = logical(str2double( ...
        s.ThorImageExperiment.LSM.Attributes.horizontalFlip ));
catch
    data.HorizontalFlip = [];
end
try
    data.VerticalFlip = logical(str2double( ...
        s.ThorImageExperiment.LSM.Attributes.verticalFlip ));
catch
    data.VerticalFlip = [];
end
try
    data.isLineScan = logical(str2double( ...
        s.ThorImageExperiment.LightPath.Attributes.GalvoGalvo ));
catch
    data.isLineScan = [];
end
