function batch_set_complete = batchsetDPE128x64(serDPE, batch_set_parameter1, batch_set_parameter2, batch_set_parameter3)
% Batch reset operations for the DPEfor 128x64 array.
% The only difference in this function is one extra bit as bottom flag to
% indicate the function is handling top 64x64 or bottom 64x64 part of the
% 128x64 array. 
% serial port must first be initialized using initializeDPEserial
% Inputs:
% 12 is for fast pulse, 18 is for slow ramp pulse. 
% Batch reset command 1: 12, number of column boards(1~8), number of row boards(1~8), column pulse width(0~1023), COL_DAC_BATCH_SPAN(5 or 10). 
% Batch reset command 2: V_BATCH_SET for column boards. Array size is previously defined by number of column and row boards.
% Batch reset command 3: V_BATCH_SET_GATE for column boards. Array size is previously defined by number of column and row boards.
%
% batch_col_parameters1 = [12,CB_NUMBER,RB_NUMBER,COL_PULSE_WIDTH_WRITE,COL_DAC_BATCH_SPAN, 0]; % Fast pulse set; Actually this function sets the device with postive voltages.
% batch_col_parameters2 = [17,CB_NUMBER,RB_NUMBER,SLOW_COL_PULSE_WIDTH_WRITE,10, 0]; % Slow pulse set; Here we use 10 as COL_DAC_BATCH_SPAN instead of 5 to force high/low switch to HIGH. Actually this function sets the device with postive voltages.

batch_set_complete = 0; 
%% Convert parameters to command strings:
if batch_set_parameter1(1) == 12
    batch_set_str1 = sprintf('%u,%u,%u,%u,%u,%u', batch_set_parameter1);
end
if batch_set_parameter1(1) == 17
    batch_set_str1 = sprintf('%u,%u,%u,%u,%u,%u', batch_set_parameter1);
end
% batch_reset_str1 = sprintf('%u,%u,%u,%u,%u', batch_reset_parameter1);
batch_set_str2 = sprintf('%.2f,', batch_set_parameter2');
batch_set_str2 = batch_set_str2(1:end-1); 
batch_set_str3 = sprintf('%.2f,', batch_set_parameter3');
batch_set_str3 = batch_set_str3(1:end-1); 

%% Send batch set commands to the DPE:
fprintf(serDPE,batch_set_str1);
pause(0.1);
fprintf(serDPE,batch_set_str2);
pause(0.1);
fprintf(serDPE,batch_set_str3);
pause(1);
while (get(serDPE, 'BytesAvailable') == 0)
end
%% IF THERE IS NO DATA?
if (get(serDPE, 'BytesAvailable')==0)
    disp('Data not avail yet.   Try again or check transmitter.')
    return
end

%% IF THERE IS DATA
%readline = 1;
while (get(serDPE, 'BytesAvailable')~=0)
    % read until terminator
    sentence = fscanf(serDPE);
    receive_data = strcat('Receive =  ',sentence);
     disp(receive_data);
    % Make sure header is there
    if length(sentence) < 5
        if strcmp(sentence(1:2),'go')
            disp('''go'' catached, DPE confirmed to excuate next command.');
        end
    else
        if strcmp(sentence(1:5),'Reset')
            disp('Batch column voltage pulse programming complete')
            batch_set_complete = 1; 
        end
    end
end