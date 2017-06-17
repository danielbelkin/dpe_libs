classdef autodpe < handle
    properties 
        serDPE
        
        totalRows = 16;
        totalCols = 16;
            
        columnGateVoltages;
        columnGainValues;
    end
    methods
        function obj = autodpe()
        % AUTODPE construct function
        
%         if nargin == 2  
%             mode = 1;
%         end     
        obj.columnGateVoltages = ones(1,obj.totalCols) * 5;
        obj.columnGainValues = ones(1,obj.totalCols) * 2;
        
        end
        
        function connect(obj)
            ComPortNumber = 4;
            BaudRateValue = 115200;
            Model_ON = 0;
            
            obj.serDPE = initializeDPEserial(ComPortNumber, BaudRateValue, Model_ON);
        end
        
        function disconnect(obj)
            closeDPEserial(obj.serDPE);
        end
        
        function output = run(obj, appliedRowVoltages_M)
            % configurations
            numAvg = 1;
            REPEAT = 1;
            
            dummy_row = 2;
            % dummy
            batch_autoDPE(obj.serDPE,appliedRowVoltages_M(1:dummy_row,:),obj.totalRows, obj.totalCols,numAvg, obj.columnGateVoltages, obj.columnGainValues,REPEAT);
            % start
            output = batch_autoDPE(obj.serDPE,appliedRowVoltages_M,obj.totalRows,obj.totalCols,numAvg,obj.columnGateVoltages,obj.columnGainValues,REPEAT);
        end
    end
end



% totalRows = 16;
% totalCols = 16;
% REPEAT = 1;
% numAvg = 1;
% % 10:0.2us; 250:1.24us; 500:2.32us; 750:3.32us; 1000:4.28us
% % Col_Pulse > Convst > Row_Pulse > Sample_Hold
% Sample_Hold = 900;
% Convst = 1010;
% Row_Pulse = 1000;
% Col_Pulse = 1020;
% columnGainValues = zeros(1,16) + 1;
% columnGateVoltages = zeros(1,16) + 5;
% appliedRowVoltages_M = temp;
% 
% batch_autoDPE(serDPE,appliedRowVoltages_M(1:1,:,1),totalRows,totalCols,columnGateVoltages,columnGainValues,Sample_Hold,Convst,Row_Pulse,Col_Pulse,numAvg,REPEAT);
% dpe_output_M = batch_autoDPE(serDPE,appliedRowVoltages_M,totalRows,totalCols,columnGateVoltages,columnGainValues,Sample_Hold,Convst,Row_Pulse,Col_Pulse,numAvg,REPEAT);
