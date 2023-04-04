
filename = strcat(mfilename('fullpath'), '.m');
[dirPath,name,ext] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

nwb=nwbRead('z-stack-down-29min.nwb');
nwb.acquisition.get('image collection').image.get('Image').data
%matnwbPath = fullpath()
%[im,coords,info]=read_tiff({'ChanA','ChanB','ChanC'},1:10,[],0);