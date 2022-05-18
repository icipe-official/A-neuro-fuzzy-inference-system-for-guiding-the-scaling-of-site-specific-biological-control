

%% Load Data

data=load("inptData.mat");
fis = readfis("insectFisl");

%% Results

% prediction Data
for month=1:12
    disp(month);
    predictionInputs = [data.tempInput(:,month)/40 data.precInput(:,month)/2982 data.windInput(:,month)/36 data.nitrInput(:,month)/12076];
    predictionOutputs=evalfis(fis,predictionInputs);
    predictionOutputs(isnan(predictionOutputs)) = 0;
    predictionOutputs(predictionOutputs<=8)=1;
    predictionOutputs(predictionOutputs>8 & predictionOutputs<=24)=2;
    predictionOutputs(predictionOutputs>24 & predictionOutputs<=44)=3;
    predictionOutputs(predictionOutputs>44)=4;
    if(~isfolder("outputData"))
        mkdir("outputData")
        
    end
    T = table(data.gridData(:,1), data.gridData(:,2), predictionOutputs);
    T.Properties.VariableNames = {'lat' 'lon' 'data'};
    writetable(T,"outputData\output"+num2str(month)+".csv");
end