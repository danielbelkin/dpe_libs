function dpe_output_M = Firmware_batch_dpe(serDPE,Vol_Only,appliedRowVoltages_M,Total_Rows,Total_Cols,Gate_Voltage,TIA_GAIN,Pulse_Width,Row_Enable,Col_Enable,Repeat)

    gainFactorTable = [1000 10000 100000 1000000];
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    sendCommand = '1024'; disp(['sendCommand = ' sendCommand]);
    fprintf(serDPE,sendCommand);
    RECEIVE_DATA = fscanf(serDPE); display(RECEIVE_DATA);
    while ~strcmp(RECEIVE_DATA(1:2),'go')
        RECEIVE_DATA = fscanf(serDPE);
        display(RECEIVE_DATA);
    end
    
    %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    flushinput(serDPE);
    Data_Rows = size(appliedRowVoltages_M,1);

    sendCommand = '20';
    sendCommand = [sendCommand ',' num2str(Vol_Only)];
    if Vol_Only == 0
        sendCommand = [sendCommand ',' num2str(Repeat)];
        sendCommand = [sendCommand ',' num2str(Pulse_Width)]; 
        Row_DAC_Span = '5';
        sendCommand = [sendCommand ',' num2str(Row_DAC_Span)];  
        sendCommand = [sendCommand ',' num2str(Total_Rows)];
        sendCommand = [sendCommand ',' num2str(Total_Cols)];
        sendCommand = [sendCommand ',' num2str(TIA_GAIN)];
        sendCommand = [sendCommand ',' num2str(Data_Rows)];
        sendCommand = [sendCommand ',' Row_Enable];
        sendCommand = [sendCommand ',' Col_Enable];
        Gate_Voltage = num2str(Gate_Voltage, '%.2f,');
        Gate_Voltage = Gate_Voltage(1:end-1);
        sendCommand = [sendCommand ',' Gate_Voltage];
    end
    fprintf(serDPE,sendCommand); 
    disp(['sendCommand = ' sendCommand]);
    
    Applied_Voltages = appliedRowVoltages_M;
    for i = 1:Data_Rows
        temp = num2str(Applied_Voltages(i,:), '%.4f,');
        temp = temp(1:end-1);
        sendCommand = [',' temp];
        fprintf(serDPE,sendCommand); 
         disp(['sendCommand = ' sendCommand]);
    end
        
    for repeat = 1:Repeat
        ADCVectorRead = [];
        RECEIVE_DATA = fscanf(serDPE); disp(RECEIVE_DATA);
        while ~strcmp(RECEIVE_DATA(1:3),'end')
            temp = str2double(strsplit(RECEIVE_DATA,','));
            if isnan(temp) ~= 1
                ADCVectorRead = [ADCVectorRead temp];
            end
            
            RECEIVE_DATA = fscanf(serDPE); disp(RECEIVE_DATA);  
        end

        ADC_Value = (reshape((ADCVectorRead-32768)*(10/65536), Total_Cols, Data_Rows))';
        dpe_output_M(:,:,repeat) = - ADC_Value / gainFactorTable(TIA_GAIN);
        
        
    end
    