addpath('/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/make_nwb/ReadImageJROI')

roiFile = '/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Marta1/fig_2_alb_kx/20230111_1_bPAC_KX_ROI1_LED1s/m1_ROI1_LED1s_kymo1.roi';
[sROI] = ReadImageJROI(roiFile);
roiRect = sROI.vnRectBounds;
y0 = roiRect(1);
x0 = roiRect(2);
y1 = roiRect(3);
x1 = roiRect(4);
roiMask = zeros(500, 500);
roiMask(y0:y1, x0:x1) = 1;

%%
tifFile = '/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Marta1/fig_2_alb_kx/20230111_1_bPAC_KX_ROI1_LED1s/m1_ROI1_LED1s.tif';
tifFileRotate = '/gpfs/fs3/archive/dkell12_lab/BrainFlowZZZ/Marta1/fig_2_alb_kx/20230111_1_bPAC_KX_ROI1_LED1s/m1_ROI1_LED1s_rotated.tif';
tifInfo = imfinfo(tifFile);
tifRotateInfo = imfinfo(tifFileRotate);