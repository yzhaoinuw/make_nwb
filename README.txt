## to load the image data
Depending on what color channels are present, specify the channel name when viewing the image data from that channel.
To see what channels are present,
```matlab
>> nwb.acquisition

ans = 

  3×1 Set array with properties:

    TwoPhotonSeriesChanA: [types.core.TwoPhotonSeries]
    TwoPhotonSeriesChanB: [types.core.TwoPhotonSeries]
    TwoPhotonSeriesChanC: [types.core.TwoPhotonSeries]
```
The above code and output tells us that there are three channels present in the nwb file, which are ChanA, ChanB, and ChanC. Then, to load the actual data from a channel,
```matlab
% to load the image data from ChanA
>> chanAdata = nwb.acquisition.get('TwoPhotonSeriesChanA').data.load();

% check its shape
>> size(chanAdata)

ans =

     1   512   512   181
```

## to get segmentation masks
For an overview of the mask for ChanA, for example,
```matlab
>> nwb.processing.get('ophys').nwbdatainterface.get('ImageSegmentation').planesegmentation.get('PlaneSegmentationChanA').image_mask.data

ans = 

  DataStub with properties:

    filename: '.\sub-BPN-M4_ses-20210524-m1_obj-1c8nyxo_ophys.nwb'
        path: '/processing/ophys/ImageSegmentation/PlaneSegmentationChanA/image_mask'
        dims: [512 512 181]
       ndims: 3
    dataType: 'logical'
```
To load the actual mask data into array (may take several seconds to load),
```matlab
% to load
>> mask = nwb.processing.get('ophys').nwbdatainterface.get('ImageSegmentation').planesegmentation.get('PlaneSegmentationChanA').image_mask.data.load();

% check its shape
>> size(mask)

ans =

   512   512   181
```
