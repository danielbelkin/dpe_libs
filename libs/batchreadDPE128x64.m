function rawADCValue = batchreadDPE128x64(serDPE, batch_read_parameters,n)
% Batch read a matrix is Raw ADC values from the DPE for 128x64 array.
% The only difference in this function is one extra bit as bottom flag to
% indicate the function is handling top 64x64 or bottom 64x64 part of the
% 128x64 array. 
% serial port must first be initialized using initializeDPEserial
% inputs: serGPS (from initializeGarmin)
% Outputs:  x (lon) and y(lat)

% An exmaple of the batch read command to DPE is:
% 10,0.1,5,3,700,800,900,1,1. Where each indicates:
% batch read select, V_read(0~5), V_gate(0~5), TIA gain number(1~4), pulse width(0~1023), S/H delay(0~1023), ADC convst delay(0~1023), number of column boards(1~8), number of row boards(1~8)

%%  initialize to nan, will have something to return even if serial comms fail
%[batch_read_select, V_read, V_gate, TIA_gain, read_pulse_width, SH_delay, ADC_convst_delay, nColBoards, nRowBoards] = textscan(commandStr, '%u%f%f%u%u%u%u%u%u', 'Delimiter',',');
% example: batch_read_parameters0 = [10,V_read0,V_gate,TIA_GAIN0,ROW_PULSE_WIDTH,SH_DELAY,ADC_CONVST_DELAY,CB_NUMBER,RB_NUMBER, 0];
batch_read_str = sprintf('%u,%.2f,%.2f,%u,%u,%u,%u,%u,%u,%u', batch_read_parameters);
%parameters = textscan(commandStr, '%u%f%f%u%u%u%u%u%u', 'Delimiter',',');
nColBoards = batch_read_parameters(8);

%% Send batch read command to the DPE:
fprintf(serDPE,batch_read_str);
pause(3);
rawADCValue = [];
while (get(serDPE, 'BytesAvailable') == 0)
end
%% IF THERE IS NO DATA?
if (get(serDPE, 'BytesAvailable')==0)
    disp('Data not avail yet.   Try again or check transmitter.')
    return
end

%% IF THERE IS DATA
readline = 1;
while (get(serDPE, 'BytesAvailable')~=0)
    % read until terminator
    sentence = fscanf(serDPE);
    receive_data = strcat('Receive =  ',sentence);
    %     disp(receive_data);
    % Make sure header is there
    if length(sentence) < 5
        if strcmp(sentence(1:2),'go')
            disp('''go'' catached, DPE confirmed to excuate next command.');
        end
    else
        if strcmp(sentence(1:5),'Batch')
            disp('Batch read complete')
        else
            temp = textscan(sentence, repmat('%u,',1,n));
            if readline <= n
                rawADCValueCell(readline,:) = temp;
            end
            readline = readline + 1;
        end
    end
end

if exist('rawADCValueCell','var')
    if isempty(rawADCValueCell)
        disp('raw ADC batch read values not received.')
    else
        try 
            rawADCValue = cell2mat(rawADCValueCell);
            if ~isempty(rawADCValue)
                disp('raw ADC batch read values succefully received.')
            end
        catch
            rawADCValue = zeros(n,n);
            disp('raw ADC batch read values not received.')
        end
    end
else
    rawADCValue = zeros(n,n);
    disp('raw ADC batch read values not received.')
end
