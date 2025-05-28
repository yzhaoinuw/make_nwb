addpath('/media/yue/make_nwb/matnwb/')

h5File = '/media/knox/glymphatic/gly_Rat/24-05-05/Particles/ThorSync_vid_083/Episode001.h5';
nwbFile = '/media/knox/glymphatic/nwb_files_keelin/gly_rat_24-05-05_particles.nwb';
%%
nwb = nwbRead(nwbFile);
acq = nwb.acquisition;
movies = acq.get('Movies');
data = movies.data;
data.internal
%info = h5info(h5File);
%data = h5read(h5File,ds);
%ecg = h5read(h5File, '/AI/ECG');
%resp = h5read(h5File, '/AI/Resp');
