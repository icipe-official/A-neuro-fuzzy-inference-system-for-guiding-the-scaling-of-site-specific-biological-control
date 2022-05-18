randperm(n,n)
    TestInputs=Inputs(nTrain+1:end,:);

[Selection, Ok] = listdlg('PromptString', 'Select training method for ANFIS:', 'SelectionMode', 'single', 'ListString', Options);