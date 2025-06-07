addpath('/media/yue/make_nwb/matnwb/')

h5File = '/media/knox/glymphatic/gly_Rat/22-07-06-rat2/Particles-down-2x/ThorSync1470/Episode001.h5';
nwbFile = '/media/knox/glymphatic/nwb_files_keelin/gly_rat_22-07-06_rat2_particles_down_2x.nwb';
%%
%nwb = nwbRead(nwbFile);
%acq = nwb.acquisition;
%movies = acq.get('Movies');
%data = movies.data;
%data.internal
info = h5info(h5File);
%ecg = h5read(h5File, '/AI/ECG');
%resp = h5read(h5File, '/AI/Resp');

