classdef appSoft < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        InsectDispUIFigure             matlab.ui.Figure
        TabGroup                       matlab.ui.container.TabGroup
        simulateTab                    matlab.ui.container.Tab
        projectFolderButton            matlab.ui.control.Button
        importdataPanel                matlab.ui.container.Panel
        Lampneig                       matlab.ui.control.Lamp
        LampInitialColonizedCells      matlab.ui.control.Lamp
        InitialColonizedCellsButton    matlab.ui.control.Button
        LampLevelProduction            matlab.ui.control.Lamp
        HostCropButton                 matlab.ui.control.Button
        SuitabilityThresholdEditField  matlab.ui.control.NumericEditField
        SuitabilityThresholdEditFieldLabel  matlab.ui.control.Label
        LampHabitatSuitability         matlab.ui.control.Lamp
        HabitatSuitabilityButton       matlab.ui.control.Button
        produceNeighbourhoodButton     matlab.ui.control.Button
        travelDistanceEditField        matlab.ui.control.NumericEditField
        travelDistanceEditFieldLabel   matlab.ui.control.Label
        LampGRid                       matlab.ui.control.Lamp
        GridButton                     matlab.ui.control.Button
        Lampshx                        matlab.ui.control.Lamp
        shxButton                      matlab.ui.control.Button
        Lampdbf                        matlab.ui.control.Lamp
        dbfButton                      matlab.ui.control.Button
        Lampshp                        matlab.ui.control.Lamp
        shpButton                      matlab.ui.control.Button
        Panel                          matlab.ui.container.Panel
        SaveVariablesButton            matlab.ui.control.Button
        TimeStepEditField              matlab.ui.control.NumericEditField
        TimeStepEditFieldLabel         matlab.ui.control.Label
        StartButton                    matlab.ui.control.Button
        mapUIAxes                      matlab.ui.control.UIAxes
    end


    properties (Access = private)
        SuitabilityThreshold = 0; %
        TimeStep = 24; %
        codeUseGrid %
        codeUseNeighbourhoodShortRange %
        codeUseLevelProduction %
        codeUseHabitatSuitability %
        InitialColonizedCells %
        idOfSiteInfected %
        idOfSiteExposed %
        idOfInitialSiteInfected %
        statut %

        k = 1; %
        month = 3; %
        projectFolder = 0; %
    end

    methods (Access = private)
        function [Idx] = neighborhood100ForDisp(~, listIdRegExpose,listVoisinage,listIdRegInfect)

            lR = length(listIdRegExpose);

            voisinage = [];

            for j=1:lR
                IdNeigbour = listVoisinage(listIdRegExpose(j),:);
                voisinage = union(voisinage,IdNeigbour(IdNeigbour<0|IdNeigbour>0));
            end
            voisinage = voisinage(voisinage>=1);
            Idx = setdiff(voisinage,listIdRegInfect);
            return;

        end

        function [outputDataFromHere, errorOut] = importDataFileHere(app, eventName ,formatFile)
            [file,path] = uigetfile(formatFile, "Select " + eventName + " file");
            if (length(formatFile)>=2)
                formatFile = formatFile(1);
            end
            fileName = fullfile(path,file);
            d = uiprogressdlg(app.InsectDispUIFigure,'Title','Please wait','Indeterminate','on');
            drawnow
            errorOut = false;
            outputDataFromHere = [];

            try
                if isequal(file,0)
                    uialert(app.InsectDispUIFigure, "Please select a " + eventName + " file", 'Selection error');
                    outputDataFromHere = [];
                    errorOut = true;
                    return;
                else


                    if(isfile(fileName))
                        if(strcmp(formatFile,"*.tif"))
                            I = imread(fileName);
                            info = geotiffinfo(fileName);
                            Latlon = app.codeUseGrid;
                            height = info.Height; % Integer indicating the height of the image in pixels
                            width = info.Width; % Integer indicating the width of the image in pixels
                            [rows,cols] = meshgrid(1:height,1:width);
                            [ADlat,ADlon] = pix2latlon(info.RefMatrix, rows, cols);
                            Idub = double(I);
                            mask = I == (intmin('int32')+1);
                            Idub(mask) = 0;
                            pixelvalues = interp2(ADlat, ADlon, Idub.', Latlon(:,1), Latlon(:,2));
                            pixelvalues(pixelvalues<=0) = 0;

                            if(~strcmp(eventName,"HabitatSuitability"))
                                pixelvalues(pixelvalues>0) = 1;

                            end
                            outputDataFromHere = pixelvalues; % import
                        elseif(strcmp(formatFile,"*.shp")||strcmp(formatFile,"*.dbf")||strcmp(formatFile,"*.shx"))
                            folderfile = app.projectFolder + "\shapefile";

                            if(~isfolder(folderfile))
                                mkdir(folderfile)

                            end
                            copyfile(fileName, folderfile + "\map" + erase(formatFile, "*"))
                        else
                            outputDataFromHere = xlsread(fileName); % import
                        end
                    else
                        uialert(app.InsectDispUIFigure, "Please select a " + eventName + " file", 'Selection error');
                        outputDataFromHere = [];
                        errorOut = true;
                        return;
                    end
                end
            catch ME
                % If problem reading file, display error message
                uialert(app.InsectDispUIFigure, ME.message, 'File Error');
                outputDataFromHere = [];
                errorOut = true;
                return;
            end

            % close the dialog box
            close(d)

        end


        function checkstart(app)


            if(strcmp(app.LampGRid.Visible, "on")&&strcmp(app.Lampneig.Visible, "on")&&strcmp(app.LampHabitatSuitability.Visible, "on")&&strcmp(app.LampLevelProduction.Visible, "on")&&strcmp(app.LampInitialColonizedCells.Visible, "on")&&strcmp(app.Lampshp.Visible, "on")&&strcmp(app.Lampdbf.Visible, "on")&&strcmp(app.Lampshx.Visible, "on"))
                app.StartButton.Enable = "on";
            else
                app.StartButton.Enable = "off";
            end


        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.SuitabilityThreshold = app.SuitabilityThresholdEditField.Value;
        end

        % Callback function: SaveVariablesButton, 
        % SuitabilityThresholdEditField
        function SaveVariablesButtonPushed(app, event)
            app.SaveVariablesButton.Visible = "off";
            app.SuitabilityThreshold = app.SuitabilityThresholdEditField.Value;
            app.SaveVariablesButton.Visible = "on";
            checkstart(app);
        end

        % Button pushed function: GridButton
        function GridButtonPushed(app, event)
            app.GridButton.Enable = "off";
            app.LampGRid.Visible = "off";
            [outputGrid, errorE] = importDataFileHere(app, event.Source.Text, ["*.xlsx";"*.xls";"*.csv"]);
            if (isempty(outputGrid) ||errorE)
                app.GridButton.Enable = "on";
                return;
            end
            gridSave = outputGrid;
            path = [app.projectFolder  '\softData.mat'];
            save(path,'gridSave', '-append')
            app.codeUseGrid = outputGrid;
            app.LampGRid.Visible = "on";
            app.GridButton.Enable = "on";
            app.produceNeighbourhoodButton.Enable = "on";
            checkstart(app);
        end

        % Close request function: InsectDispUIFigure
        function InsectDispUIFigureCloseRequest(app, event)
            delete(app)

        end

        % Button pushed function: HabitatSuitabilityButton
        function HabitatSuitabilityButtonPushed(app, event)
            app.HabitatSuitabilityButton.Enable = "off";
            app.LampHabitatSuitability.Visible = "off";
            [outputGrid, errorE] = importDataFileHere(app, event.Source.Text,"*.tif");
            if (isempty(outputGrid) || isempty(app.codeUseGrid) || errorE)
                app.HabitatSuitabilityButton.Enable = "on";
                return;
            end
            suitabilitySave = outputGrid;
            path = [app.projectFolder  '\softData.mat'];
            save(path,'suitabilitySave', '-append')
            app.codeUseHabitatSuitability = outputGrid;
            app.LampHabitatSuitability.Visible = "on";
            app.HabitatSuitabilityButton.Enable = "on";
            app.HostCropButton.Enable = "on";
            checkstart(app);
        end

        % Button pushed function: HostCropButton
        function HostCropButtonPushed(app, event)
            app.HostCropButton.Enable = "off";
            app.LampLevelProduction.Visible = "off";
            [outputGrid, errorE] = importDataFileHere(app, event.Source.Text,"*.tif");
            if (isempty(outputGrid) || isempty(app.codeUseGrid) || errorE)
                app.HostCropButton.Enable = "on";
                return;
            end
            cropSave = outputGrid;
            path = [app.projectFolder  '\softData.mat'];
            save(path,'cropSave', '-append')
            app.codeUseLevelProduction = outputGrid;
            app.LampLevelProduction.Visible = "on";
            app.HostCropButton.Enable = "on";
            checkstart(app);
            app.InitialColonizedCellsButton.Enable = "on";
            checkstart(app);
        end

        % Button pushed function: InitialColonizedCellsButton
        function InitialColonizedCellsButtonPushed(app, event)
            app.InitialColonizedCellsButton.Enable = "off";
            app.LampInitialColonizedCells.Visible = "off";
            coloData = zeros(length(app.codeUseGrid),1);
            [outputGrid, errorE] = importDataFileHere(app, event.Source.Text, ["*.xlsx";"*.xls";"*.csv"]);
            if (isempty(outputGrid) || isempty(app.codeUseGrid) || errorE)
                app.InitialColonizedCellsButton.Enable = "on";
                return;
            end
            l= length(outputGrid);
            for count=1:l
                %     disp(num2str(j) + " out of " + num2str(l))

                rangeDistance = deg2km(distance(outputGrid(count,:),app.codeUseGrid));
                IdLong= find(rangeDistance==min(rangeDistance));
                IdShort= IdLong(1);
                coloData(IdShort) = 1;
            end
            colonizedSave = coloData;

            path = [app.projectFolder  '\softData.mat'];
            save(path,'colonizedSave', '-append')
            app.InitialColonizedCells = coloData;
            app.LampInitialColonizedCells.Visible = "on";
            app.InitialColonizedCellsButton.Enable = "on";
            checkstart(app);
        end

        % Button pushed function: produceNeighbourhoodButton
        function produceNeighbourhoodButtonPushed(app, event)
            app.produceNeighbourhoodButton.Enable = "off";
            app.Lampneig.Visible = "off";
            atet = true;
            try
                gridSave = app.codeUseGrid;
                path = [app.projectFolder  '\softData.mat'];
                distancShort1 = app.travelDistanceEditField.Value;

                l= length(gridSave);
                dataShort1 = zeros(l,1);
                d = uiprogressdlg(app.InsectDispUIFigure,'Title','running neigbourhood','Message','1','Cancelable','on');
                drawnow

                for ncount=1:l
                    %     disp(num2str(j) + " out of " + num2str(l))
                    % Check for Cancel button press
                    if d.CancelRequested
                        atet = false;
                        break
                    end
                    % Update progress, report current estimate
                    d.Value = ncount/l;
                    percentValue = floor((ncount/l)*100);
                    d.Message = sprintf('%d%% ',percentValue);
                    ptReg = gridSave(ncount,:);
                    rangeDistance = deg2km(distance(ptReg,gridSave));
                    IdShortFun= find(rangeDistance<=distancShort1)';
                    if(~isempty(IdShortFun))
                        IdDataShortFunc = setdiff(IdShortFun,ncount);
                        dataShort1(ncount,1:length(IdDataShortFunc)) = IdDataShortFunc;
                    end
                end
                save(path,'dataShort1','-append')

                % Close the dialog box
                close(d)
            catch ME
                % If problem reading file, display error message
                uialert(app.InsectDispUIFigure, ME.message, 'neighbour Error');
                return;
            end
            app.produceNeighbourhoodButton.Enable = "on";
            if atet
                app.Lampneig.Visible = "on";
                app.HabitatSuitabilityButton.Enable = "on";
            end
            checkstart(app);






        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            try
                video_name = [app.projectFolder  '\dispersal.mp4'];
                videompg4 = VideoWriter(video_name, 'MPEG-4');
                open(videompg4);
                app.StartButton.Enable = "off";
                app.GridButton.Enable = "off";
                app.HabitatSuitabilityButton.Enable = "off";
                app.HostCropButton.Enable = "off";
                app.produceNeighbourhoodButton.Enable = "off";
                app.InitialColonizedCellsButton.Enable = "off";
                app.shpButton.Enable = "off";
                app.dbfButton.Enable = "off";
                app.shxButton.Enable = "off";
                app.projectFolderButton.Enable = "off";
                app.TimeStep = app.TimeStepEditField.Value;
                app.idOfSiteInfected = find(app.InitialColonizedCells>=1);
                app.idOfInitialSiteInfected = app.idOfSiteInfected;
                app.idOfSiteExposed = app.idOfSiteInfected;
                path = [app.projectFolder  '\softData.mat'];
                myVars = {'dataShort1'};
                S = load(path,myVars{:});
                app.codeUseNeighbourhoodShortRange = S.dataShort1;
                path = [app.projectFolder  '\shapefile\map.shp'];

                land = shaperead(path, 'UseGeoCoords', true);
                geoshow(land, 'FaceColor', [0.15 0.5 0.15],"Parent",app.mapUIAxes)
                geoshow(app.codeUseGrid(app.idOfInitialSiteInfected,1),app.codeUseGrid(app.idOfInitialSiteInfected,2), 'Marker', '*','DisplayType', 'point','Color', [0.0 0.0 0.0],'MarkerEdgeColor', 'auto',"Parent",app.mapUIAxes);

                pause(0.01)
                app.k = 1;




                app.statut = zeros(length(app.codeUseGrid),1);
                app.statut(app.idOfSiteInfected) = 2;
                folderfile = app.projectFolder + "\outputData";

                if(~isfolder(folderfile))
                    mkdir(folderfile)

                end
                for timeStep=1:app.TimeStep
                    infectData = app.idOfSiteInfected;
                    exposeData = app.idOfSiteExposed;
                    neighbourData = app.codeUseNeighbourhoodShortRange;

                    [IdVoisin] = neighborhood100ForDisp(app, [exposeData;infectData],neighbourData,infectData);


                    if( mod((timeStep-1),12) ==0)
                        app.month=3;% first month
                    end




                    for p=1:length(IdVoisin) % Neighbourhood

                        idMax  =IdVoisin(p); % cellIdNeighbourhood
                        app.statut(idMax) = 1;
                        if(app.codeUseHabitatSuitability(idMax)>app.SuitabilityThreshold && app.codeUseLevelProduction(idMax)>= 1 && app.statut(idMax) ~= 2 )
                            app.statut(idMax) = 2;

                        end





                    end





                    app.idOfSiteExposed = find (app.statut==1);
                    app.idOfSiteInfected = find (app.statut==2);
                    regInfect = app.codeUseGrid(app.idOfSiteInfected,1:2);
                    regExpose = app.codeUseGrid(app.idOfSiteExposed,1:2);

                    app.month=app.month+1; % next month
                    geoshow(regExpose(:,1),regExpose(:,2), 'Marker', '.', 'DisplayType', 'point', 'MarkerSize', 10, 'Color', [0.980400 0.949000 0.058800],'MarkerEdgeColor', 'auto',"Parent",app.mapUIAxes);
                    pause(0.001)
                    geoshow(regInfect(:,1),regInfect(:,2), 'Marker', '.', 'DisplayType', 'point', 'MarkerSize', 10, 'Color', [1 0.1 0.1],'MarkerEdgeColor', 'auto',"Parent",app.mapUIAxes);
                    pause(0.001)
                    geoshow(app.codeUseGrid(app.idOfInitialSiteInfected,1),app.codeUseGrid(app.idOfInitialSiteInfected,2), 'Marker', '*','DisplayType', 'point','Color', [0.0 0.0 0.0],'MarkerEdgeColor', 'auto',"Parent",app.mapUIAxes);
                    pause(0.001)
                    frame = getframe(app.mapUIAxes);
                    writeVideo(videompg4,frame);
                    T = table(app.codeUseGrid(:,1), app.codeUseGrid(:,2), app.statut);
                    T.Properties.VariableNames = {'lat' 'lon' 'data'};
                    writetable(T,folderfile + "\output"+num2str(timeStep)+".csv");
                    app.k = app.k+1;


                end
                close(videompg4);
                app.StartButton.Enable = "on";
                app.GridButton.Enable = "on";
                app.HabitatSuitabilityButton.Enable = "on";
                app.HostCropButton.Enable = "on";
                app.produceNeighbourhoodButton.Enable = "on";
                app.InitialColonizedCellsButton.Enable = "on";
                app.shpButton.Enable = "on";
                app.dbfButton.Enable = "on";
                app.shxButton.Enable = "on";
                app.projectFolderButton.Enable = "on";
            catch ME
                app.StartButton.Enable = "on";
                app.GridButton.Enable = "on";
                app.HabitatSuitabilityButton.Enable = "on";
                app.HostCropButton.Enable = "on";
                app.produceNeighbourhoodButton.Enable = "on";
                app.InitialColonizedCellsButton.Enable = "on";
                app.shpButton.Enable = "on";
                app.dbfButton.Enable = "on";
                app.shxButton.Enable = "on";
                app.projectFolderButton.Enable = "on";
                % If problem reading file, display error message
                uialert(app.InsectDispUIFigure, ME.message, 'File Error');
                return;
            end
        end

        % Button pushed function: shpButton
        function shpButtonPushed(app, event)
            app.shpButton.Enable = "off";
            app.Lampshp.Visible = "off";
            [~, errorE] = importDataFileHere(app, event.Source.Text, "*.shp");
            if (errorE)
                app.shpButton.Enable = "on";
                return;
            end
            app.Lampshp.Visible = "on";
            app.shpButton.Enable = "on";
            checkstart(app);
        end

        % Button pushed function: dbfButton
        function dbfButtonPushed(app, event)
            app.dbfButton.Enable = "off";
            app.Lampdbf.Visible = "off";
            [~, errorE] = importDataFileHere(app, event.Source.Text, "*.dbf");
            if (errorE)
                app.dbfButton.Enable = "on";
                return;
            end
            app.Lampdbf.Visible = "on";
            app.dbfButton.Enable = "on";
            checkstart(app);
        end

        % Button pushed function: shxButton
        function shxButtonPushed(app, event)
            app.shxButton.Enable = "off";
            app.Lampshx.Visible = "off";
            [~, errorE] = importDataFileHere(app, event.Source.Text, "*.shx");
            if (errorE)
                app.shxButton.Enable = "on";
                return;
            end
            app.Lampshx.Visible = "on";
            app.shxButton.Enable = "on";
            checkstart(app);
        end

        % Button pushed function: projectFolderButton
        function projectFolderButtonPushed(app, event)
            try
                app.projectFolderButton.Enable = "off";
                path = uigetdir('title','Select project directory');
                app.projectFolderButton.Enable = "on";
                if (path==0)
                    return;
                end
                app.projectFolder = path;
                if(isfolder(path + "\shapefile"))
                    if(isfile(path + "\shapefile\map.shp"))
                        app.shpButton.Enable = "on";
                        app.Lampshp.Visible = "on";

                    else
                        app.shpButton.Enable = "on";
                        app.Lampshp.Visible = "off";

                    end
                    if(isfile(path + "\shapefile\map.dbf"))
                        app.dbfButton.Enable = "on";
                        app.Lampdbf.Visible = "on";

                    else
                        app.dbfButton.Enable = "on";
                        app.Lampdbf.Visible = "off";

                    end
                    if(isfile(path + "\shapefile\map.shx"))
                        app.shxButton.Enable = "on";
                        app.Lampshx.Visible = "on";

                    else
                        app.shxButton.Enable = "on";
                        app.Lampshx.Visible = "off";

                    end

                else
                    app.shpButton.Enable = "on";
                    app.Lampshp.Visible = "off";
                    app.dbfButton.Enable = "on";
                    app.Lampdbf.Visible = "off";
                    app.shxButton.Enable = "on";
                    app.Lampshx.Visible = "off";

                end
                if(isfile(path + "\softData.mat"))
                    myVars = {'gridSave',"suitabilitySave","cropSave","colonizedSave","dataShort1"};
                    S = load(path + "\softData.mat",myVars{:});
                    a = S.gridSave;
                    b = S.suitabilitySave;
                    c = S.cropSave;
                    d = S.colonizedSave;
                    e = S.dataShort1;
                    if(a==1)
                        app.GridButton.Enable = "on";
                        app.LampGRid.Visible = "off";
                        app.HabitatSuitabilityButton.Enable = "off";
                        app.LampHabitatSuitability.Visible = "off";
                        app.HostCropButton.Enable = "off";
                        app.LampLevelProduction.Visible = "off";
                        app.produceNeighbourhoodButton.Enable = "off";
                        app.Lampneig.Visible = "off";
                        app.InitialColonizedCellsButton.Enable = "off";
                        app.LampInitialColonizedCells.Visible = "off";
                        return;

                    else
                        app.codeUseGrid = a;
                        app.GridButton.Enable = "on";
                        app.LampGRid.Visible = "on";
                        if(b==1)
                            app.HabitatSuitabilityButton.Enable = "on";
                            app.LampHabitatSuitability.Visible = "off";

                        else
                            app.codeUseHabitatSuitability = b;
                            app.HabitatSuitabilityButton.Enable = "on";
                            app.LampHabitatSuitability.Visible = "on";

                        end
                        if(c==1)
                            app.HostCropButton.Enable = "on";
                            app.LampLevelProduction.Visible = "off";

                        else
                            app.codeUseLevelProduction = c;
                            app.HostCropButton.Enable = "on";
                            app.LampLevelProduction.Visible = "on";

                        end
                        if(d==1)
                            app.InitialColonizedCellsButton.Enable = "on";
                            app.LampInitialColonizedCells.Visible = "off";

                        else
                            app.InitialColonizedCells = d;
                            app.InitialColonizedCellsButton.Enable = "on";
                            app.LampInitialColonizedCells.Visible = "on";

                        end
                        if(e==1)
                            app.produceNeighbourhoodButton.Enable = "on";
                            app.Lampneig.Visible = "off";

                        else
                            app.codeUseNeighbourhoodShortRange = e;
                            app.produceNeighbourhoodButton.Enable = "on";
                            app.Lampneig.Visible = "on";

                        end

                    end

                else
                    gridSave = 1;
                    suitabilitySave = 1;
                    cropSave = 1;
                    colonizedSave = 1;
                    dataShort1 = 1;
                    save(path + "\softData.mat",'gridSave','suitabilitySave','cropSave','colonizedSave','dataShort1')
                    app.GridButton.Enable = "on";
                    app.LampGRid.Visible = "off";
                    app.HabitatSuitabilityButton.Enable = "off";
                    app.LampHabitatSuitability.Visible = "off";
                    app.HostCropButton.Enable = "off";
                    app.LampLevelProduction.Visible = "off";
                    app.produceNeighbourhoodButton.Enable = "off";
                    app.Lampneig.Visible = "off";
                    app.InitialColonizedCellsButton.Enable = "off";
                    app.LampInitialColonizedCells.Visible = "off";

                end
                checkstart(app);
            catch ME
                % If problem reading file, display error message
                uialert(app.InsectDispUIFigure, ME.message, 'File Error');
                return;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create InsectDispUIFigure and hide until all components are created
            app.InsectDispUIFigure = uifigure('Visible', 'off');
            app.InsectDispUIFigure.Position = [100 100 871 485];
            app.InsectDispUIFigure.Name = 'Insect Disp';
            app.InsectDispUIFigure.Resize = 'off';
            app.InsectDispUIFigure.CloseRequestFcn = createCallbackFcn(app, @InsectDispUIFigureCloseRequest, true);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.InsectDispUIFigure);
            app.TabGroup.Position = [2 -12 871 498];

            % Create simulateTab
            app.simulateTab = uitab(app.TabGroup);
            app.simulateTab.Title = 'simulate';
            app.simulateTab.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create mapUIAxes
            app.mapUIAxes = uiaxes(app.simulateTab);
            title(app.mapUIAxes, 'Spread')
            xlabel(app.mapUIAxes, 'lat')
            ylabel(app.mapUIAxes, 'lon')
            zlabel(app.mapUIAxes, 'Z')
            app.mapUIAxes.Position = [335 85 516 381];

            % Create Panel
            app.Panel = uipanel(app.simulateTab);
            app.Panel.TitlePosition = 'centertop';
            app.Panel.BackgroundColor = [0.902 0.902 0.902];
            app.Panel.Position = [335 42 509 44];

            % Create StartButton
            app.StartButton = uibutton(app.Panel, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.BackgroundColor = [0.651 0.651 0.651];
            app.StartButton.FontWeight = 'bold';
            app.StartButton.FontColor = [0.149 0.149 0.149];
            app.StartButton.Enable = 'off';
            app.StartButton.Position = [400 11 100 24];
            app.StartButton.Text = 'Start';

            % Create TimeStepEditFieldLabel
            app.TimeStepEditFieldLabel = uilabel(app.Panel);
            app.TimeStepEditFieldLabel.HorizontalAlignment = 'right';
            app.TimeStepEditFieldLabel.Position = [10 12 58 22];
            app.TimeStepEditFieldLabel.Text = 'TimeStep';

            % Create TimeStepEditField
            app.TimeStepEditField = uieditfield(app.Panel, 'numeric');
            app.TimeStepEditField.Limits = [1 Inf];
            app.TimeStepEditField.Position = [83 12 100 22];
            app.TimeStepEditField.Value = 1;

            % Create SaveVariablesButton
            app.SaveVariablesButton = uibutton(app.Panel, 'push');
            app.SaveVariablesButton.ButtonPushedFcn = createCallbackFcn(app, @SaveVariablesButtonPushed, true);
            app.SaveVariablesButton.HorizontalAlignment = 'left';
            app.SaveVariablesButton.BackgroundColor = [0.651 0.651 0.651];
            app.SaveVariablesButton.FontSize = 14;
            app.SaveVariablesButton.FontWeight = 'bold';
            app.SaveVariablesButton.FontColor = [0 0.4471 0.7412];
            app.SaveVariablesButton.Position = [236 11 118 25];
            app.SaveVariablesButton.Text = 'Save Variables';

            % Create importdataPanel
            app.importdataPanel = uipanel(app.simulateTab);
            app.importdataPanel.ForegroundColor = [0 0 1];
            app.importdataPanel.TitlePosition = 'centertop';
            app.importdataPanel.Title = 'import data';
            app.importdataPanel.BackgroundColor = [0.902 0.902 0.902];
            app.importdataPanel.Position = [1 41 334 394];

            % Create shpButton
            app.shpButton = uibutton(app.importdataPanel, 'push');
            app.shpButton.ButtonPushedFcn = createCallbackFcn(app, @shpButtonPushed, true);
            app.shpButton.BackgroundColor = [0.651 0.651 0.651];
            app.shpButton.FontWeight = 'bold';
            app.shpButton.FontColor = [0.149 0.149 0.149];
            app.shpButton.Enable = 'off';
            app.shpButton.Position = [10 7 45 24];
            app.shpButton.Text = 'shp';

            % Create Lampshp
            app.Lampshp = uilamp(app.importdataPanel);
            app.Lampshp.Visible = 'off';
            app.Lampshp.Position = [57 8 20 20];

            % Create dbfButton
            app.dbfButton = uibutton(app.importdataPanel, 'push');
            app.dbfButton.ButtonPushedFcn = createCallbackFcn(app, @dbfButtonPushed, true);
            app.dbfButton.BackgroundColor = [0.651 0.651 0.651];
            app.dbfButton.FontWeight = 'bold';
            app.dbfButton.FontColor = [0.149 0.149 0.149];
            app.dbfButton.Enable = 'off';
            app.dbfButton.Position = [122 7 45 24];
            app.dbfButton.Text = 'dbf';

            % Create Lampdbf
            app.Lampdbf = uilamp(app.importdataPanel);
            app.Lampdbf.Visible = 'off';
            app.Lampdbf.Position = [170 9 20 20];

            % Create shxButton
            app.shxButton = uibutton(app.importdataPanel, 'push');
            app.shxButton.ButtonPushedFcn = createCallbackFcn(app, @shxButtonPushed, true);
            app.shxButton.BackgroundColor = [0.651 0.651 0.651];
            app.shxButton.FontWeight = 'bold';
            app.shxButton.FontColor = [0.149 0.149 0.149];
            app.shxButton.Enable = 'off';
            app.shxButton.Position = [234 6 45 24];
            app.shxButton.Text = 'shx';

            % Create Lampshx
            app.Lampshx = uilamp(app.importdataPanel);
            app.Lampshx.Visible = 'off';
            app.Lampshx.Position = [281 9 20 20];

            % Create GridButton
            app.GridButton = uibutton(app.importdataPanel, 'push');
            app.GridButton.ButtonPushedFcn = createCallbackFcn(app, @GridButtonPushed, true);
            app.GridButton.BackgroundColor = [0.651 0.651 0.651];
            app.GridButton.FontWeight = 'bold';
            app.GridButton.FontColor = [0.149 0.149 0.149];
            app.GridButton.Enable = 'off';
            app.GridButton.Position = [71 340 133 24];
            app.GridButton.Text = 'Grid';

            % Create LampGRid
            app.LampGRid = uilamp(app.importdataPanel);
            app.LampGRid.Visible = 'off';
            app.LampGRid.Position = [207 342 20 20];

            % Create travelDistanceEditFieldLabel
            app.travelDistanceEditFieldLabel = uilabel(app.importdataPanel);
            app.travelDistanceEditFieldLabel.HorizontalAlignment = 'right';
            app.travelDistanceEditFieldLabel.Position = [71 295 83 22];
            app.travelDistanceEditFieldLabel.Text = 'travelDistance';

            % Create travelDistanceEditField
            app.travelDistanceEditField = uieditfield(app.importdataPanel, 'numeric');
            app.travelDistanceEditField.Limits = [0 Inf];
            app.travelDistanceEditField.Position = [169 295 100 22];

            % Create produceNeighbourhoodButton
            app.produceNeighbourhoodButton = uibutton(app.importdataPanel, 'push');
            app.produceNeighbourhoodButton.ButtonPushedFcn = createCallbackFcn(app, @produceNeighbourhoodButtonPushed, true);
            app.produceNeighbourhoodButton.BackgroundColor = [0.651 0.651 0.651];
            app.produceNeighbourhoodButton.FontWeight = 'bold';
            app.produceNeighbourhoodButton.FontColor = [0.149 0.149 0.149];
            app.produceNeighbourhoodButton.Enable = 'off';
            app.produceNeighbourhoodButton.Position = [70 248 148 24];
            app.produceNeighbourhoodButton.Text = 'produceNeighbourhood';

            % Create HabitatSuitabilityButton
            app.HabitatSuitabilityButton = uibutton(app.importdataPanel, 'push');
            app.HabitatSuitabilityButton.ButtonPushedFcn = createCallbackFcn(app, @HabitatSuitabilityButtonPushed, true);
            app.HabitatSuitabilityButton.BackgroundColor = [0.651 0.651 0.651];
            app.HabitatSuitabilityButton.FontWeight = 'bold';
            app.HabitatSuitabilityButton.FontColor = [0.149 0.149 0.149];
            app.HabitatSuitabilityButton.Enable = 'off';
            app.HabitatSuitabilityButton.Position = [71 202 133 24];
            app.HabitatSuitabilityButton.Text = 'HabitatSuitability';

            % Create LampHabitatSuitability
            app.LampHabitatSuitability = uilamp(app.importdataPanel);
            app.LampHabitatSuitability.Visible = 'off';
            app.LampHabitatSuitability.Position = [205 206 20 20];

            % Create SuitabilityThresholdEditFieldLabel
            app.SuitabilityThresholdEditFieldLabel = uilabel(app.importdataPanel);
            app.SuitabilityThresholdEditFieldLabel.HorizontalAlignment = 'right';
            app.SuitabilityThresholdEditFieldLabel.Position = [71 158 116 22];
            app.SuitabilityThresholdEditFieldLabel.Text = 'Suitability Threshold';

            % Create SuitabilityThresholdEditField
            app.SuitabilityThresholdEditField = uieditfield(app.importdataPanel, 'numeric');
            app.SuitabilityThresholdEditField.Limits = [0 Inf];
            app.SuitabilityThresholdEditField.ValueChangedFcn = createCallbackFcn(app, @SaveVariablesButtonPushed, true);
            app.SuitabilityThresholdEditField.Position = [202 158 100 22];

            % Create HostCropButton
            app.HostCropButton = uibutton(app.importdataPanel, 'push');
            app.HostCropButton.ButtonPushedFcn = createCallbackFcn(app, @HostCropButtonPushed, true);
            app.HostCropButton.BackgroundColor = [0.651 0.651 0.651];
            app.HostCropButton.FontWeight = 'bold';
            app.HostCropButton.FontColor = [0.149 0.149 0.149];
            app.HostCropButton.Enable = 'off';
            app.HostCropButton.Position = [71 112 133 24];
            app.HostCropButton.Text = 'HostCrop';

            % Create LampLevelProduction
            app.LampLevelProduction = uilamp(app.importdataPanel);
            app.LampLevelProduction.Visible = 'off';
            app.LampLevelProduction.Position = [206 114 20 20];

            % Create InitialColonizedCellsButton
            app.InitialColonizedCellsButton = uibutton(app.importdataPanel, 'push');
            app.InitialColonizedCellsButton.ButtonPushedFcn = createCallbackFcn(app, @InitialColonizedCellsButtonPushed, true);
            app.InitialColonizedCellsButton.BackgroundColor = [0.651 0.651 0.651];
            app.InitialColonizedCellsButton.FontWeight = 'bold';
            app.InitialColonizedCellsButton.FontColor = [0.149 0.149 0.149];
            app.InitialColonizedCellsButton.Enable = 'off';
            app.InitialColonizedCellsButton.Position = [74 66 128 24];
            app.InitialColonizedCellsButton.Text = 'InitialColonizedCells';

            % Create LampInitialColonizedCells
            app.LampInitialColonizedCells = uilamp(app.importdataPanel);
            app.LampInitialColonizedCells.Visible = 'off';
            app.LampInitialColonizedCells.Position = [204 68 20 20];

            % Create Lampneig
            app.Lampneig = uilamp(app.importdataPanel);
            app.Lampneig.Visible = 'off';
            app.Lampneig.Position = [221 250 20 20];

            % Create projectFolderButton
            app.projectFolderButton = uibutton(app.simulateTab, 'push');
            app.projectFolderButton.ButtonPushedFcn = createCallbackFcn(app, @projectFolderButtonPushed, true);
            app.projectFolderButton.BackgroundColor = [0.651 0.651 0.651];
            app.projectFolderButton.FontWeight = 'bold';
            app.projectFolderButton.FontColor = [0.149 0.149 0.149];
            app.projectFolderButton.Position = [1 443 203 24];
            app.projectFolderButton.Text = 'projectFolder';

            % Show the figure after all components are created
            app.InsectDispUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = appSoft

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.InsectDispUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.InsectDispUIFigure)
        end
    end
end