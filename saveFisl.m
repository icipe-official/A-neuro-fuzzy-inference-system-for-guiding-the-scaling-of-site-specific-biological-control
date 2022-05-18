

%% Load Data

data=load("DataFisl.mat");
fis = readfis("insectFisl");

%% Results

% Train Data
TrainOutputs=evalfis(fis,data.TrainIn);
PlotResults(data.TrainTa,TrainOutputs,'Train Data');

% Test Data
TestOutputs=evalfis(fis,data.TestIn);
PlotResults(data.TestTa,TestOutputs,'Test Data');