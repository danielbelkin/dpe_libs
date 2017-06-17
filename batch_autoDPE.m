function dpe_output_M = batch_autoDPE(serDPE,appliedRowVoltages_M,totalRows,totalCols,columnGateVoltages,columnGainValues,Sample_Hold,Convst,Row_Pulse,Col_Pulse,numAvg,REPEAT)

    rowBoardMapping = [0 1 2 3 4 5 6 7];
	colBoardMapping = [0 1 2 3 4 5 6 7];
    gainFactorTable = [1000 10000 100000 1000000];
    separator= ',';
    groundEverythingSelect = 1;
    DPEOneColumnAtATime = 0;
    Sample_And_Hold = num2str(Sample_Hold);
    ADC_ConvSt = num2str(Convst);
    Row_Pulse_Width = num2str(Row_Pulse);
    Col_Pulse_Width = num2str(Col_Pulse);
    
    totalRows_input = size(appliedRowVoltages_M,1);
    dpe_output_M = zeros(totalRows_input,round(totalCols),REPEAT,size(appliedRowVoltages_M,3));
    numAvg = round(max(1, numAvg)); 
    
    time_per_cycle = 2.3945;
    tic;
    
for number = 1:size(appliedRowVoltages_M,3)
    for repeat = 1:round(REPEAT)
        for cycle = 1:totalRows_input
            time_left = (totalRows_input - cycle) + (REPEAT - repeat ) * totalRows_input + (size(appliedRowVoltages_M,3) - number ) * REPEAT * totalRows_input;
            time_left = datestr(time_left * time_per_cycle/86400, 'HH:MM:SS');
            
            display(['DPE Operation On:' num2str(cycle) '/' num2str(totalRows_input) '--' num2str(repeat) '/' num2str(REPEAT) '--' num2str(number) '/' num2str(size(appliedRowVoltages_M,3)) ' Time left est. ' time_left]);
            
            appliedRowVoltages = appliedRowVoltages_M(cycle,:,number);
            if DPEOneColumnAtATime == 0
                numRowBoards = ceil(totalRows/16);
                numColBoards = ceil(totalCols/8);
                Ivalue = zeros(1,8*numColBoards, numAvg);
                activeRows = zeros(1,16*numRowBoards);
                activeRows(1:totalRows) = 1;

                for i = 1:numRowBoards
                    startRow = 16*(i-1)+1;
                    endRow = 16*(i);
                    calibrate_all_DPE_row(serDPE, Row_Pulse_Width, rowBoardMapping(i), activeRows(startRow:endRow), appliedRowVoltages(startRow:endRow));
                    sendCommand = ['1024'];
                    fprintf(serDPE, sendCommand);        
                    RECEIVE_DATA = fscanf(serDPE);
                    while ~strcmp(RECEIVE_DATA(1:2),'go')
                        RECEIVE_DATA = fscanf(serDPE);
                        %disp('Row-RECEIVE_DATA:', RECEIVE_DATA);
                    end
                    while serDPE.BytesAvailable >1
                        RxText = fscanf(serDPE);
                        %disp('Row-RxText:', RxText);
                    end
                end

                for j = 1:numColBoards
                    startCol = 8*(j-1)+1;
                    endCol = 8*j;
                    %display(['t:' num2str(j) ' startcol:' num2str(startCol) ' endCol:' num2str(endCol)]);
                    calibrate_all_DPE_col(serDPE, Col_Pulse_Width, Sample_And_Hold, ADC_ConvSt, colBoardMapping(j), columnGateVoltages(startCol:endCol), columnGainValues(startCol:endCol));
                    sendCommand = ['1024'];
                    fprintf(serDPE, sendCommand);        
                    RECEIVE_DATA = fscanf(serDPE);
                    while ~strcmp(RECEIVE_DATA(1:2),'go')
                        RECEIVE_DATA = fscanf(serDPE);
                        %disp('Col-RECEIVE_DATA:', RECEIVE_DATA);
                    end
                    while serDPE.BytesAvailable >1
                        RxText = fscanf(serDPE);
                        %disp('Col-RxText:', RxText);
                    end
                end

                for k = 1:numAvg      
                    for j = 1:numColBoards
                        sendCommand = ['1024'];
                        fprintf(serDPE,sendCommand);
                        RECEIVE_DATA = fscanf(serDPE); %display(RECEIVE_DATA);
                        while ~strcmp(RECEIVE_DATA(1:2),'go')
                            RECEIVE_DATA = fscanf(serDPE);
                            %disp('numAvg-RECEIVE_DATA:', RECEIVE_DATA);
                        end
                        while serDPE.BytesAvailable >1
                            RxText = fscanf(serDPE);
                            %disp('numAvg-RxText:', RxText);
                        end

                        sendCommand = ['4'];
                        sendColumnBoardNum = num2str(colBoardMapping(j));
                        sendCommand = [sendCommand ',' sendColumnBoardNum];
                        fprintf(serDPE,sendCommand);
                        ADCVectorStrings{j,k} = fscanf(serDPE); %display(ADCVectorString);
                        while strcmp(ADCVectorStrings{j,k}(1:2),'go')
                            ADCVectorStrings{j,k} = fscanf(serDPE); %display(ADCVectorString);
                        end
                        RECEIVE_DATA = fscanf(serDPE); %display(RECEIVE_DATA);
                        while ~strcmp(RECEIVE_DATA(1:2),'go')
                            RECEIVE_DATA = fscanf(serDPE);
                        end
                    end
                end

                if groundEverythingSelect == 1
                    newGroundEveryRowColumn(serDPE);
                end

                for k = 1:numAvg
                    for j = 1:numColBoards
                        D = strsplit(ADCVectorStrings{j,k},separator);
                        for i = 1:8
                            ADCVectorRead = str2double(char(D{i}));
                            ADC_value = (ADCVectorRead-32768)*(10/65536);
                            Ivalue(1,((j-1)*8+i),k) = ADC_value/(-1*gainFactorTable(columnGainValues(((j-1)*8+i))));
                        end
                    end
                end
                avgIvalue = mean(Ivalue,3,'omitnan');
                dpe_output_M(cycle,:,repeat,number) = avgIvalue(1:totalCols);  
                
                figure(99); plot(1:totalCols, avgIvalue(1:totalCols));
                drawnow;
            end
        end
    end
end
time_run = toc;
display( ['DPE complete! total time is: ' datestr(time_run /86400, 'HH:MM:SS') ]);