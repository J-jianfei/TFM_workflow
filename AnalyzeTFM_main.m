clear
clc
close all

% 
disp("This analysis script provides entries of traction field visualization and basic analysis.");
disp("IMPORTANT: This is specifically designed for the output of TFM_main.m, and it will not work with other data.");
disp("Please make sure you have the output file of TFM_main.m ready.");
disp("visulization consists of two types: magnitude and vector. Please select one of them.");
disp("Basic analysis includes: mean, median, max, min, and standard deviation of the traction magnitude within a given ROI.");
disp("Please follow the instructions in the command window to proceed.");





% Load the data
[filename, pathname] = uigetfile('*.mat', 'Select the TFM_output file genereated by TFM_main.m');

if(isequal(filename,0))
    error('No file was selected');
end

if(~exist(fullfile(pathname, filename), 'file'))
    error('File does not exist');
end


