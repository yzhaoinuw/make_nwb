function [img,coords,info]=read_raw(infile,frlist,xmlfile,noisy)
% Usage: [img,coords,info] = read_raw(infile,[frlist],[xmlfile],[noisy])'])
% Given a file "infile" saved in .raw format by the ThorImage software,
% read_raw reads the file. If the file contains a two-dimensional movie,
% read_raw reads the frames in the sorted list of frame numbers "frlist",
% returning the output in "img", a cell array with one element for each
% color channel, and with each element containing a three-dimensional array
% of size Nrows x Ncolumns x Nframes, where Nrows is the number of rows in
% the movie, Ncolumns is the number of columns, and Nframes is the number
% of elements in "frlist". If the file contains one-dimensional line scans,
% read_raw interprets "frlist" as a sorted list of line numbers, and "img"
% is returned with each of its elements containing a two-dimensional array
% of size Nrows x Nlines, where Nlines is the number of elements in
% "frlist". Corresponding coordiates and their units are returned in the
% struct "coords". By default, movie metadata is read from
% 'Experiment.xml'; to use a different file, provide its name in "xmlfile".
% Metadata is returned in "info"; info.isLineScan indicates whether
% "infile" contained a movie or line scans, and info.FrameRate indicates
% the frequency at which images or lines were acquired, and
% info.TimingSource tells which file was used to produce frame times. If
% noisy~=0, data are visualized using imagei.m. If "infile" contains a
% two-dimensional movie and the directory containing "infile" also contains
% a file called 'reg.mat', images are registered according to its contents
% (see reg_raw.m); info.isReg indicates whether images have been
% registered. Requires read_Thor_xml.m and xml2struct.m. Requires imagei.m for
% visualization, and imagei.m requires superSlider.m (codelib\boster\FileExchange\superSlider)

% Written by Rebeca Toro. 
% Major update 7 October 2019 by Doug Kelley: made compatibile with new
% version of read_Thor_xml.m, changed inputs and outputs for usability,
% allowed saving movies to disk, simplified algorithm.
% Minor updates 10 October 2019 by Jeff Tithof: changed satlims from [1 99]
% to [1 99.95], changed shiftfile name to simply 'reg.mat' from
% 'registration_shifts_calculated1.mat'
% Updated 14 January 2020 by Doug Kelley: Fixed transposition error in
% fread lines, removed 180 degree rotation from plotting so image
% orientation matches microscope screen.
% Updated 27 January 2020: now correctly handling files where more frames
% were allocated than recorded, and now giving info.RecordedFrames as
% output.
% Updated 3 February 2020 to fail gracefully if file not found. 
% Updated 16 May 2020 to ignore xml files and registration files not in
% same directory as raw file (but elsewhere on the path), and to ignore raw
% files elsewhere on the path. And now plotting using imagei.m.
% Updated 24 May 2020 for compatibility with new version of imagei.m. 
% Updated 19 April 2021: Now compatible with line scan data, and now
% enforcing HorizontalFlip and VerticalFlip. 
% Bug fixes 21 April 2021: HorizontalFlip and VerticalFlip no longer cause
% errors. Now respecting the data type (uint8, uint16) of line scans. No
% longer unnecessarily giving warning about registration being unsupported
% with line scans. Now giving correct times for linescans in coords.T. 
% Bug fix 27 April 2021: With line scans, RecordedFrames and
% AllocatedFrames now count lines. 
% Bug fix 7 June 2022: If frlist is empty or does not exist, it now reads
% all frames from info.RecordedFrames instead of info.AllocatedFrames.
% Update 18 January 2023: Now getting individual frame times from
% Episode001.h5, instead of etimating frame times from average frame rate
% in Experiment.xml, if possible. 

% -=- Constants -=-
xmlfile_default = 'Experiment.xml'; % default name used by ThorImage software
h5_list = 'ThorSync*/Episode001.h5';
noisy_default = 0; % plot only if requested
shiftfile = 'reg.mat';
T_tol = 1e-9; % (seconds); used to say if line rate is constant
clockRate = 2e7; % (Hz), hard-coded from ThorLabs

assert(nargin>0,['Usage: [img,coords,info] = ' mfilename ...
    '(infile,[frlist],[xmlfile],[noisy])'])
if ~exist('xmlfile','var') || isempty(xmlfile)
    xmlfile=xmlfile_default;
end
if ~exist('noisy','var') || isempty(noisy)
    noisy=noisy_default;
end

finfo=dir(infile);
assert(~isempty(finfo),['Sorry, cannot find ' infile '.'])
rawpath=fileparts(infile);
shiftfile=fullfile(rawpath,shiftfile); % specify full path to stay in same directory
xmlpath=fileparts(xmlfile);
if isempty(xmlpath)
    xmlfile=fullfile(rawpath,xmlfile); % specify full path to stay in same directory
end
info=read_Thor_xml(xmlfile);
if info.ImageBitDepthReal <= 8
    typestr='uint8';
    BytesPerFrame=info.ImageHeight*info.ImageWidth*info.NumCh*1;
else
    typestr='uint16';
    BytesPerFrame=info.ImageHeight*info.ImageWidth*info.NumCh*2;
end % Does ThorLabs raw format support other bit depths?
info.RecordedFrames=finfo.bytes/BytesPerFrame;
if ~exist('frlist','var') || isempty(frlist)
    frlist=1:info.RecordedFrames; % by default, read all frames
else
    assert(all(diff(frlist)>0), ...
        'Sorry, frlist must sorted in increasing order')
    frlist(frlist<1)=[];
    if info.isLineScan
        lnlist = frlist; % user-requested lines
        lnlist(lnlist>info.RecordedFrames*info.ImageHeight)=[];
        myfr_list = ceil(lnlist/info.ImageHeight); % frame from which to get each requested line
        myln_list = mod(lnlist,info.ImageHeight); % line, within each frame, from which to get each requested line
        myln_list(myln_list==0) = info.ImageHeight;
        frlist = unique(myfr_list); % frames to be read
        Nl = numel(lnlist); % count of lines
    else
        frlist(frlist>info.RecordedFrames)=[];
    end
end % if ~exist('frlist','var') || isempty(frlist)
assert(~isempty(frlist),['Sorry, ' infile ...
    ' does not contain any of the requested frames.'])
frlist=frlist(:)'; % force to row vector, to match sh.rsh and sh.csh
if exist(shiftfile,'file') && ~info.isLineScan
    info.isReg=true;
    sh=load(shiftfile);
else
    if exist(shiftfile,'file') && info.isLineScan
        warning('Sorry, line scan registration is not supported.')
    end
    info.isReg=false;
    sh=struct;
    sh.rsh=zeros(info.RecordedFrames,1); % no shift
    sh.csh=zeros(info.RecordedFrames,1); % no shift
end
fin=fopen(infile,'r'); % Open raw file
n=numel(frlist); % frames to be read
padx=ceil([max(max(sh.csh),0) abs(min(min(sh.csh),0))]); % Calculate padding
pady=ceil([max(max(sh.rsh),0) abs(min(min(sh.rsh),0))]);
nr=info.ImageHeight+sum(pady); % determine dimensions needed
nc=info.ImageWidth+sum(padx);
Nr=ifftshift(-fix(nr/2):ceil(nr/2)-1);
Nc=ifftshift(-fix(nc/2):ceil(nc/2)-1);
[Nc,Nr]= meshgrid(Nc,Nr); % Make meshgrid of coordinates for shifting images
img=cell(1,info.NumCh);
for i=1:info.NumCh
    img{i}=zeros(nr,nc,n,typestr); % initialize output
end
for i=1:n
    fseek(fin,(frlist(i)-1)*BytesPerFrame,'bof'); % jump to desired frame
    if info.isReg
        Z=zeros(nr,nc,info.NumCh);
        for j=1:info.NumCh
            Z(1+pady(2):end-pady(1),1+padx(2):end-padx(1),j) = ...
                double(reshape( ...
                    fread(fin,info.ImageHeight*info.ImageWidth, ...
                    [typestr '=>' typestr]), ...
                    info.ImageWidth,info.ImageHeight)');
            Z(:,:,j) = real(abs(ifft2(fft2(Z(:,:,j)).* ...
                exp(1i*2*pi*(-sh.rsh(frlist(i))*Nr/nr - ...
                sh.csh(frlist(i))*Nc/nc)))));
        end % for j=1:info.NumCh
    else % if info.isReg
        Z=permute(reshape( ...
            fread(fin,info.NumCh*info.ImageHeight*info.ImageWidth, ...
            [typestr '=>' typestr]), ...
            info.ImageWidth,info.ImageHeight,info.NumCh),[2 1 3]);
    end % if info.isReg
    switch info.NumCh
        case 1
            img{1}(:,:,i)=cast(Z,typestr);
        case 2
            img{1}(:,:,i)=cast(Z(:,:,1),typestr);
            img{2}(:,:,i)=cast(Z(:,:,2),typestr);
        case 3
            img{1}(:,:,i)=cast(Z(:,:,2),typestr);
            img{2}(:,:,i)=cast(Z(:,:,3),typestr);
            img{3}(:,:,i)=cast(Z(:,:,1),typestr); % channel order differs for 3-channel
    end % switch info.NumCh
end % for i=1:n
if info.HorizontalFlip
    img = cellfun(@fliplr,img,'uniformoutput',false);
end
if info.VerticalFlip
    img = cellfun(@flipud,img,'uniformoutput',false);
end
info.ImageHeight=nr; % make metadata match output, not input
info.ImageWidth=nc;
fclose(fin);
coords=struct;
coords.X=(0:info.ImageWidth-1)*info.umperpix;
coords.X_unit='microns';
coords.Y=(0:info.ImageHeight-1)*info.umperpix;
coords.Y_unit='microns';
h5_file = dir(h5_list);
if ~isempty(h5_file) % try to get timing from .h5
    h5_file = fullfile(h5_file.folder,h5_file.name); % convert struct to string
    h5_info = h5info(h5_file);
    for ii = 1:numel(h5_info.Groups)
        for jj = 1:numel(h5_info.Groups(ii).Datasets)
            datasetPath = [ h5_info.Groups(ii).Name '/' ...
                h5_info.Groups(ii).Datasets(jj).Name ];
            datasetName = h5_info.Groups(ii).Datasets(jj).Name;
            if strcmp(h5_info.Groups(ii).Name,'/Global') % global counter
                coords.T = double(h5read(h5_file,datasetPath))/clockRate;
            end
            if info.isLineScan && ... % timing for line scans
                ( strcmp(datasetName,'GGLineTriggerOut') || ...
                strcmp(datasetName,'GG Line Trigger Out') )
                FrameOut = h5read(h5_file,datasetPath);
            elseif ~info.isLineScan && ... % timing for images
                ( strcmp(datasetName,'FrameOut') || ...
                strcmp(datasetName,'Frame Out') )
                FrameOut = h5read(h5_file,datasetPath);
            end
        end
    end
    dFO = double(FrameOut(2:end)) - double(FrameOut(1:end-1));
    thr = mean(dFO) + [-1 1]*std(dFO);
    FOstart = find(dFO>thr(2))+1;
    FOend = find(dFO<thr(1))+1;
    FOmean = round((FOstart+FOend)/2);
    coords.T = coords.T(FOmean);
    info.TimingSource = h5_list;
    info.FrameRate = 1/mean(diff(coords.T));
else % get timing from .xml
    coords.T=(0:info.RecordedFrames-1)/info.FrameRate;
    info.TimingSource = xmlfile;
end
if info.isLineScan
    coords.T=coords.T(lnlist);
else
    coords.T=coords.T(frlist);
end
coords.T_unit='seconds';

% -=- If line scan, adjust -=-
if info.isLineScan
    img1 = cell(1,info.NumCh);
    for ii = 1:info.NumCh
        img1{ii} = zeros(info.ImageWidth,Nl,typestr);
        for jj = 1:Nl
            img1{ii}(:,jj) = img{ii}(myln_list(jj),:, ...
                myfr_list(jj)-myfr_list(1)+1);
        end
    end
    img = img1;
    clear img1 % save memory
    coords.Y = [];
    info.AllocatedFrames = info.AllocatedFrames*info.ImageHeight;
    info.RecordedFrames = info.RecordedFrames*info.ImageHeight;
end % if info.isLineScan

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
        switch info.NumCh
            case 1
                imagei(coords.T,coords.X,[],{img{1} img{1} img{1}})
            case 2
                imagei(coords.T,coords.X,[],{img{1} img{2} 0*img{1}})
            case 3
                imagei(coords.T,coords.X,[],img)
        end % switch info.NumCh
        xlabel(['t (' coords.T_unit ')'])
        ylabel(['x (' coords.X_unit ')'])
    else
        if ~isnumeric(noisy)
            MovName=noisy;
        else
            MovName=[];
        end
        switch info.NumCh
            case 1
                imagei(coords.X,coords.Y,coords.T, ...
                    {img{1} img{1} img{1}},MovName)
            case 2
                imagei(coords.X,coords.Y,coords.T, ...
                    {img{1} img{2} 0*img{1}},MovName)
            case 3
                imagei(coords.X,coords.Y,coords.T,img,MovName)
        end % switch info.NumCh
        xlabel(['x (' coords.X_unit ')'])
        ylabel(['y (' coords.Y_unit ')'])
    end % if info.isLineScan
end % if noisy~=0
