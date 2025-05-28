function [img,coords,info] = read_tiff(imgfile,frlist,xmlfile,noisy)
% useage: [img,coords,info] = read_tiff(imgfile,frlist,xmlfile,noisy)
%READ_TIFF reads in a series of .tiff files and returns the conents of the
%file, coords, and info, similar to read_raw. 
% imgfile is a 1X3 cell containing the names of the channels you want to
% read into the different cells of img. Example:
% imgfile={'ChanA','ChanB','ChanC'}; 
% the rest of the inputs and outputs are like read_raw
% Kimberly Boster, kboster@ur.rochester.edu

%improvements: make reading in files more general
% change imgfile from a cell array of the channels to a path. It's not that
% important to set the channel.
% get rid of readExperiment
% add the ability to automatically apply a registration like read_raw does
% add comments
% make it work if you provide a path, like read_raw does


assert(nargin>0,['Usage: [img,coords,info] = ' mfilename ...
    '(infile,[frlist],[xmlfile],[noisy])'])
if ~exist('xmlfile','var') || isempty(xmlfile)
    xmlfile='Experiment.xml';
end
if ~exist('noisy','var') || isempty(noisy)
    noisy=noisy_default;
end

info=read_Thor_xml(xmlfile);
Experiment=readExperiment(xmlfile);

if ~exist('frlist','var') || isempty(frlist)
    frlist=1:Experiment.NumIm; % by default, read all frames
end

ctr=1;
for ii=frlist
    if mod(ctr,100)==0
        disp(['Importing image ' num2str(ctr) ' of ' num2str(length(frlist))])
    end
    for cc=1:length(imgfile)
        if strcmp(imgfile{cc},'0')
            img{cc}(:,:,ctr)=zeros(Experiment.pixelY,Experiment.pixelX);
        elseif Experiment.NumZ>1
            img{cc}(:,:,ctr)=imread([imgfile{cc} '_0001_0001_',num2str(ii,'%04d') '_0001.tif']);
        else
            img{cc}(:,:,ctr)=imread([imgfile{cc} '_0001_0001_0001_',num2str(ii,'%04d') '.tif']);
        end
    end    
    ctr=ctr+1;
end


coords=struct;
coords.X=(0:info.ImageWidth-1)*info.umperpix;
coords.X_unit='microns';
coords.Y=(0:info.ImageHeight-1)*info.umperpix;
coords.Y_unit='microns';
if Experiment.NumZ>1
    coords.Z=(0:Experiment.NumZ-1)*Experiment.stepSizeUM;
    coords.Z=coords.Z(frlist);
    coords.Z_unit='microns';
    coords.S=coords.Z;
else
    coords.T=(0:Experiment.NumT-1)/info.FrameRate;
    coords.T=coords.T(frlist);
    coords.T_unit='seconds';
    coords.S=coords.T;
end

%% I took the rest of this code straight from read_raw.m
if info.HorizontalFlip
    img = cellfun(@fliplr,img,'uniformoutput',false);
end
if info.VerticalFlip
    img = cellfun(@flipud,img,'uniformoutput',false);
end
% -=- Plot if requested -=-
if noisy~=0
disp('Plotting...')
    if info.isLineScan
        dT = unique(diff(coords.T));
        if any(abs(dT-mean(dT))>T_tol)
            warning(['Sorry, cannot plot lines recorded at ' ...
                'non-uniform intervals.'])
            return
        else
            disp('Plotting...')
        end
%         switch info.NumCh
%             case 1
%                 imagei(coords.T,coords.X,[],{img{1} img{1} img{1}})
%             case 2
%                 imagei(coords.T,coords.X,[],{img{1} img{2} 0*img{1}})
%             case 3
                imagei(coords.T,coords.X,[],img)
%         end % switch info.NumCh
        xlabel(['t (' coords.T_unit ')'])
        ylabel(['x (' coords.X_unit ')'])
    else
        if ~isnumeric(noisy)
            MovName=noisy;
        else
            MovName=[];
        end
        switch length(img)
            case 1
                imagei(coords.X,coords.Y,coords.S, ...
                    {img{1} img{1} img{1}},MovName)
            case 2
                imagei(coords.X,coords.Y,coords.S, ...
                    {img{1} img{2} 0*img{1}},MovName)
            case 3
                imagei(coords.X,coords.Y,coords.S,img,MovName)
        end % switch info.NumCh
        xlabel(['x (' coords.X_unit ')'])
        ylabel(['y (' coords.Y_unit ')'])
    end % if info.isLineScan
end % if noisy~=0



end

