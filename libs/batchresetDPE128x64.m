function batch_reset_complete = batchresetDPE128x64(serDPE, batch_reset_parameter1, batch_reset_parameter2, batch_reset_parameter3)
% Batch set operations for the DPE for 128x64 array.
% The only difference in this function is one extra bit as bottom flag to
% indicate the function is handling top 64x64 or bottom 64x64 part of the
% 128x64 array.
% serial port must first be initialized using initializeDPEserial
% Inputs:
% Batch set command 1: 11, number of column boards(1~8), number of row boards(1~8), row pulse width(0~1023), COL_DAC_BATCH_SPAN, ROW_DAC_BATCH_SPAN
% Batch set command 2: V_BATCH_SET for row boards. Array size is previously defined by number of column and row boards.
% Batch set command 3: V_BATCH_SET_GATE for column boards. Array size is previously defined by number of column and row boards.
%
batch_reset_complete = 0;

%example:

%batch_row_parameters1 = [11,CB_NUMBER,RB_NUMBER,ROW_PULSE_WIDTH_WRITE,COL_DAC_BATCH_SPAN,ROW_DAC_BATCH_SPAN, 0]; % Fast pulse reset; Actually function resets the device with postive voltages.
%batch_row_parameters1 = [18,CB_NUMBER,RB_NUMBER,SLOW_ROW_PULSE_WIDTH_WRITE, 0]; % Slow pulse reset; Actually function resets the device with postive voltages.

%% Convert parameters to command strings:
if batch_reset_parameter1(1) == 11
    batch_reset_str1 = sprintf('%u,%u,%u,%u,%u,%u,%u', batch_reset_parameter1);
end
if batch_reset_parameter1(1) == 18
    batch_reset_str1 = sprintf('%u,%u,%u,%u,%u', batch_reset_parameter1);
end
% batch_set_str1 = sprintf('%u,%u,%u,%u,%u,%u', batch_set_parameter1);
batch_reset_str2 = sprintf('%.2f,', batch_reset_parameter2');
batch_reset_str2 = batch_reset_str2(1:end-1);
batch_reset_str3 = sprintf('%.2f,', batch_reset_parameter3');
batch_reset_str3 = batch_reset_str3(1:end-1);
%% Send batch set commands to the DPE:
fprintf(serDPE,batch_reset_str1);
pause(0.1);
fprintf(serDPE,batch_reset_str2);
pause(0.1);
fprintf(serDPE,batch_reset_str3);
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
        if strcmp(sentence(1:3),'Set')
            disp('Batch row voltage complete')
            batch_reset_complete = 1;
        end
    end
end


