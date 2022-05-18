inptData = xlsread("Clean_data.csv");
Inputs = inptData(:,1:4);
Targets = inptData(:,5)*100;
save("insectData", "Inputs", "Targets");