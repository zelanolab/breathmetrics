# BreathMetrics
### Version 2.0
### 9/22/2019

BreathMetrics is a Matlab toolbox for analyzing respiratory recordings.

Respiratory signals contain a wealth of information but they can be quite challenging to analyze because breathing is inhearently complex and respiratory recordings tend to be prone to noise. Breathmetrics was designed to make analyzing respiratory recordings easier.


Breathmetrics is a matlab class with functions that serve four purposes:
1. Extracting features such as times of breath onsets, volumes of individual breaths, and pauses in breathing. 
2. Calculating summary statistics of breathing such as breathing rate, minute ventilation, and tidal volume. 
3. Visualizing, editing, and annotating these features using several methods including a GUI.

<img src="img/readme_fig1.png" width="600" />

### BreathMetrics Accurately Estimates Features of Complex, Noisy, Human Respiratory Signals

The ability to algorithmically obtain the parameters of breathing in a raw recording is important for many reasons. Basic metrics, such as knowing whether a person is breathing or not, have obvious importance for health but accurately quantifying features like onsets, durations, and volumes of individual breaths is critical for research investigating the biology and neuroscience of breathing and olfaction. There are a multitude of features embedded in respiratory signals that are poorly understood and investigating them may reveal new insights about their biological underpinnings and how they correlate with disease.


Human breathing waveforms are surprisingly complex. Individuals regularly breathe at varying rates, with different individual breath volumes and waveforms, and may choose to pause their breathing for up to minutes at a time. These innate aspects of human respiratory signals make them difficult to analyze because they don’t meet the assumptions made by most traditional automated digital signal processing analyses. In this way, other methods must be used to accurately extract the many important breathing characteristics hidden in respiratory signals. By developing an algorithm that accurately parameterizes human breathing recordings, we provide a much-needed computational tool for many facets of health research as well as olfactory and respiratory neuroscience. This method was rigorously validated using several methods on multiple datasets exhibiting a wide range of respiratory features. In this way, we hope this tool will allow researchers to ask new questions about how respiration relates to brain, body, and behavior.




## Example Output

### Structure And Parameterization of BreathMetrics Class Object

<img src="img/readme_class_full_output.png" width="400" />


#### Visualizing Features Calculated Using BreathMetrics

<img src="img/readme_visualization.png" width="800" />


#### GUI for Manual Inspection of Individual Respiratory Events

todo


## Usage
First clone this repository and append it to your Matlab path.

Instructions for using this toolbox (calculating specific features and accessing them) are described in demo.m

To reproduce the figures above, navigate to the breathmetrics directory and run:

```matlab
respiratoryData = load('sample_data.mat');
respiratoryTrace = respiratoryData.resp;
srate = respiratoryData.srate;
dataType = 'humanAirflow';
bm = breathmetrics(respiratoryTrace, srate, dataType);
bm.estimateAllFeatures();
fig = bm.plotCompositions('raw');
fig = bm.plotFeatures({'extrema','maxflow'});
fig = bm.plotCompositions('normalized');
fig = bm.plotCompositions('line');
bm.launchGUI();
```

## Dependencies:
Breathmetrics is designed to be used with Matlab2019A. It has been tested and works with older versions dating back to Matlab2016A with no errors being noted.

Only the instantaneus phase estimation function (which is not recommended) is dependent on the Matlab Signal Processing Toolbox.

## This toolbox is maintained by the following people at the Human Neuroscience Lab at Northwestern University:
* Torben Noto
* Guangyu Zhou
* Gregory Lane
* Christina Zelano


## Thanks to the following collaborators who contributed code and data:
* Behzad Iravani & Johan Lundstrom (Code)
* Minghong Ma (Rodent Data)
* Andrew Moberly (Rodent Data)
* Leslie Kay (Rodent Data)
* Sam Cooler (GUI assistance)

## Reference
A PDF of the peer-reviewed paper validating the methods we use here can be found in this directory.

If you would like to use this code in your project, please cite:

    Noto, T., Zhou, G., Schuele, S., Templer, J., & Zelano, C. (2018). 
    Automated analysis of breathing waveforms using BreathMetrics: 
    A respiratory signal processing toolbox. Chemical Senses, 43(8), 583–597. 
    https://doi.org/10.1093/chemse/bjy045



### This code is hosted publicly at https://github.com/zelanolab/breathmetrics and is supported by the following National Institutes of Health (NIDCD) grants:
* R00-DC-012803 to CZ
* R01-DC-016364 to CZ
* T32-NS047987 to TN

