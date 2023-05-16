
filename = strcat(mfilename('fullpath'), '.m');
[dirPath,name,ext] = fileparts(filename);
addpath(fullfile(dirPath, 'matnwb'))

%nwb = nwbRead('.\BrainWaveZZZ_Data\zstack-up-41min.nwb');
nwb = nwbRead('.\sub-BPN-M4_ses-20210524-m1_obj-1c8nyxo_ophys.nwb');
%nwb.acquisition.get('image collection').image.get('Image').data
%matnwbPath = fullpath()
%[im,coords,info]=read_tiff({'ChanA','ChanB','ChanC'},1:10,[],0);