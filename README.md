# BreathMetrics
BreathMetrics is a Matlab toolbox for algorithmic feature extraction of human respiratory flow data developed by a team at the Northwestern Human Neuroscience Lab, led by Dr. Christina Zelano.

BreathMetrics has functions to extract features such as times of breath onsets, volumes of individual breaths, and pauses in breathing, as well as summary statistics such as breathing rate, minute ventilation, and tidal volume. These features can also be visualized in several ways.

## Example Output

### Structure And Paramaterization of BreathMetrics Class Object

![BreathMetrics Class Structure](img/readme_class_output.png "BreathMetrics Class Structure")


#### Visualizing Features Calculated Using BreathMetrics 

![BreathMetrics Visualizations](img/readme_visualization.png "BreathMetrics Visualizations")


## Usage
First clone this repository and append it to your Matlab path.

Instructions for using this toolbox (calculating specific features and accessing them) are described in demo.m

To reproduce the figures above, move to the breathmetrics directory and run:

```matlab
respiratoryData = load('sample_data.mat');
respiratoryTrace = respiratoryData.resp;
srate = respiratoryData.srate;
dataType = 'human';
bm = breathmetrics(respiratoryTrace, srate, dataType);
bm.estimateAllFeatures();
fig = bm.plotCompositions('raw');
fig = bm.plotFeatures({'extrema','maxflow'});
fig = bm.plotCompositions('normalized');
fig = bm.plotCompositions('line');
```

## Dependencies
Matlab 2017b
