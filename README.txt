# to get segmentation masks
nwb.processing.get('ophys').nwbdatainterface.get('ImageSegmentation')
nwb.processing.get('ophys').nwbdatainterface.get('ImageSegmentation').planesegmentation.get('PlaneSegmentationChanA').image_mask

# to load compressed data (DataPipe object)
data = nwb.acquisition.get('TwoPhotonSeriesChanA').data;
twoPhotonData = data.load();