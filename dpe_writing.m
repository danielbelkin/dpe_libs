classdef dpe_writing < handle
    properties
        serDPE;
        
        TOL_ROW = 128;
        TOL_COL = 64;
        
        CB_NUMBER;
        RB_NUMBER;
        
        IV_GAIN_FACTOR = [1000,10000,100000,1000000];
        
        ROW_PULSE_WIDTH = 1000;
        COL_PULSE_WIDTH = 1020;
        SH_DELAY = 900;
        ADC_CONVST_DELAY = 1010;
        
        COL_DAC_BATCH_SPAN = 5;
        ROW_DAC_BATCH_SPAN = 5;

        % Set and Reset pulse width settings
        ROW_PULSE_WIDTH_WRITE = 1000; % RESET; 0 means 160 ns, 193 is 1 us.
        COL_PULSE_WIDTH_WRITE = 1000; % SET; 1000 means 4.3 us, 15 is 200 ns.
        SLOW_COL_PULSE_WIDTH_WRITE = 15; % No matter how you define it here, it would be ~5ms.
        SLOW_ROW_PULSE_WIDTH_WRITE = 500; % it is about 500 us.  
    end
    
    methods
        function obj = dpe_writing()
            obj.CB_NUMBER = ceil( obj.TOL_COL / 8);
            obj.RB_NUMBER = ceil( obj.TOL_ROW / 16);


        end
        
        function connect(obj)
            Model_ON = 0;
            ComPortNumber = 4;
            BaudRateValue = 115200;
            [obj.serDPE] = initializeDPEserial(ComPortNumber, BaudRateValue, Model_ON);
        end
        
        function disconnect(obj)
            closeDPEserial(obj.serDPE);
        end
        
        function [V_ADC, G_read] = batch_read(obj, V_read1, TIA_GAIN1)
            % Read voltage settings.
%             V_read1 = 0.2;    % function input now.
%             TIA_GAIN1 = 2;    % funcitno input now

            V_gate = 5;
            
            rawADCValue = [];

            batch_read_parameters1 = [10,V_read1,V_gate,TIA_GAIN1, obj.ROW_PULSE_WIDTH, obj.SH_DELAY, obj.ADC_CONVST_DELAY, obj.CB_NUMBER, obj.RB_NUMBER,0];
            batch_read_parameters1_b = [10,V_read1,V_gate,TIA_GAIN1, obj.ROW_PULSE_WIDTH, obj.SH_DELAY, obj.ADC_CONVST_DELAY, obj.CB_NUMBER, obj.RB_NUMBER,1];
            
            return2top = returntop(obj.serDPE);
            display(['Reading top 64x64 array with Gain = ', num2str(TIA_GAIN1), '.']);
            temp = batchreadDPE128x64(obj.serDPE, batch_read_parameters1, obj.TOL_COL);
            while ( size(temp) ~= [64,64] )
                display('Reading error, re-read');
                
                return2top = returntop(obj.serDPE);
                display(['Reading top 64x64 array with Gain = ', num2str(TIA_GAIN1), '.']);
                temp = batchreadDPE128x64(obj.serDPE, batch_read_parameters1, obj.TOL_COL);
            end
            rawADCValue(1:64,1:64) = temp;
            
            return2top = returntop(obj.serDPE);
            display(['Reading bottom 64x64 array with Gain = ', num2str(TIA_GAIN1), '.']);
            temp = batchreadDPE128x64(obj.serDPE, batch_read_parameters1_b,obj.TOL_COL);
            while ( size(temp) ~= [64,64] ) 
                display('Reading error, re-read');
                
                return2top = returntop(obj.serDPE);
                display(['Reading top 64x64 array with Gain = ', num2str(TIA_GAIN1), '.']);
                temp = batchreadDPE128x64(obj.serDPE, batch_read_parameters1_b, obj.TOL_COL);
            end
            rawADCValue(65:128,1:64) = temp;
            
            temp_1 = double(rawADCValue);

%             temp_1_store(read_ct, :) = temp_1(:);
            
            V_ADC_1 = (reshape(temp_1, obj.TOL_ROW, obj.TOL_COL) - 32768) .* (10 / 65536);
%             V_ADC_store_1(1:TOL_ROW, ((cycle-1)*TOL_COL+1):((cycle-1)*TOL_COL+TOL_COL)) = V_ADC_1;
            G_read1 = - V_ADC_1 ./ obj.IV_GAIN_FACTOR(TIA_GAIN1) ./ V_read1;
            
            V_ADC = V_ADC_1;
            G_read = G_read1;
%             G_read_store(1:TOL_ROW, ((cycle-1)*TOL_COL+1):((cycle-1)*TOL_COL+TOL_COL)) = G_read;
        end
        
        function [batch_row_complete, batch_col_complete] = write(obj, V_batch_set, V_batch_gate_set, V_batch_reset, V_batch_gate_reset)
%             batch_row_parameters2 = [18,CB_NUMBER,RB_NUMBER,SLOW_ROW_PULSE_WIDTH_WRITE,0]; % Slow pulse reset; Actually function resets the device with postive voltages.
%             batch_col_parameters1 = [12,CB_NUMBER,RB_NUMBER,COL_PULSE_WIDTH_WRITE,COL_DAC_BATCH_SPAN,0]; % Fast pulse set; Actually this function sets the device with postive voltages.
            
%             batch_row_parameters2_b = [18,CB_NUMBER,RB_NUMBER,SLOW_ROW_PULSE_WIDTH_WRITE,1]; % Slow pulse reset; Actually function resets the device with postive voltages.
%             batch_col_parameters1_b = [12,CB_NUMBER,RB_NUMBER,COL_PULSE_WIDTH_WRITE,COL_DAC_BATCH_SPAN,1]; % Fast pulse set; Actually this function sets the device with postive voltages.
            batch_col_complete = obj.set(V_batch_set, V_batch_gate_set);
            batch_row_complete = obj.reset(V_batch_reset, V_batch_gate_reset);
        end
        
        function batch_col_complete = batch_set(obj, V_batch_set, V_batch_gate_set)
            batch_col_parameters2 = [17, obj.CB_NUMBER, obj.RB_NUMBER, obj.SLOW_COL_PULSE_WIDTH_WRITE, 10, 0]; % Slow pulse set; Here we use 10 as COL_DAC_BATCH_SPAN instead of 5 to force high/low switch to HIGH. Actually this function sets the device with postive voltages.
            batch_col_parameters2_b = [17, obj.CB_NUMBER, obj.RB_NUMBER, obj.SLOW_COL_PULSE_WIDTH_WRITE, 10, 1]; % Slow pulse set; Here we use 10 as COL_DAC_BATCH_SPAN instead of 5 to force high/low switch to HIGH. Actually this function sets the device with postive voltages.

            % Program top 64x64
            returntop(obj.serDPE);
            display(['Column positive voltages to top 64x64 array.']);
            batch_col_complete = batchsetDPE128x64(obj.serDPE, batch_col_parameters2, V_batch_set(1:64,1:64), V_batch_gate_set(1:64,1:64));
            display(batch_col_complete);
            % Program bottom 64x64;
            returntop(obj.serDPE);
            display(['Column positive voltages to bottom 64x64 array.']);
            batch_col_complete = batchsetDPE128x64(obj.serDPE, batch_col_parameters2_b, V_batch_set(65:128,1:64), V_batch_gate_set(65:128,1:64));
        end
        
        function batch_row_complete = batch_reset(obj, V_batch_reset, V_batch_gate_reset)
            batch_row_parameters1 = [11, obj.CB_NUMBER, obj.RB_NUMBER, obj.ROW_PULSE_WIDTH_WRITE, obj.COL_DAC_BATCH_SPAN, obj.ROW_DAC_BATCH_SPAN,0]; % Fast pulse reset; Actually function resets the device with postive voltages.
            batch_row_parameters1_b = [11, obj.CB_NUMBER, obj.RB_NUMBER, obj.ROW_PULSE_WIDTH_WRITE, obj.COL_DAC_BATCH_SPAN, obj.ROW_DAC_BATCH_SPAN,1]; % Fast pulse reset; Actually function resets the device with postive voltages.
            
            % Program top 64x64
            returntop(obj.serDPE);
            display(['Row positive voltages to top 64x64 array.']);
            batch_row_complete = batchresetDPE128x64(obj.serDPE, batch_row_parameters1, V_batch_reset(1:64,1:64), V_batch_gate_reset(1:64,1:64));
            display(batch_row_complete);
            % Program bottom 64x64;
            returntop(obj.serDPE);
            display(['Row positive voltages to bottom 64x64 array.']);
            batch_row_complete = batchresetDPE128x64(obj.serDPE, batch_row_parameters1_b, V_batch_reset(65:128,1:64), V_batch_gate_reset(65:128,1:64));
        end
    end
end