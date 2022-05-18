%
% Copyright (c) 2015, Yarpiz (www.yarpiz.com)
% All rights reserved. Please read the "license.txt" for license terms.
%
% Project Code: YPFZ104
% Project Title: Evolutionary ANFIS Traing in MATLAB
% Publisher: Yarpiz (www.yarpiz.com)
% 
% Developer: S. Mostapha Kalami Heris (Member of Yarpiz Team)
% 
% Contact Info: sm.kalami@gmail.com, info@yarpiz.com
%

function data=LoadData()

    data=load('insectData.mat');
    Inputs=data.Inputs;
    Targets=data.Targets;
%     comment below to remove class
%     Targets(Targets<=8)=1;
%     Targets(Targets>8 & Targets<=24)=2;
%     Targets(Targets>24 & Targets<=44)=3;
%     Targets(Targets>44)=4;
%     comment above to remove class
    Targets=Targets(:,1);
    
    nSample=size(Inputs,1);
    
    % Shuffle Data
    S=randperm(nSample);
    Inputs=Inputs(S,:);
    Targets=Targets(S,:);
    
    % Train Data
    pTrain=0.7;
    nTrain=round(pTrain*nSample);
    TrainInputs=Inputs(1:nTrain,:);
    TrainTargets=Targets(1:nTrain,:);
    
    % Test Data
    TestInputs=Inputs(nTrain+1:end,:);
    TestTargets=Targets(nTrain+1:end,:);
    
    % Export
    data.TrainInputs=TrainInputs;
    data.TrainTargets=TrainTargets;
    data.TestInputs=TestInputs;
    data.TestTargets=TestTargets;

end