function return2top = returntop(serDPE)
fprintf(serDPE,'1024');
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
    %     disp(receive_data);
    % Make sure header is there
    if length(sentence) < 5
        if strcmp(sentence(1:2),'go')
            disp('''go'' catached, DPE confirmed to excuate next command.');
            return2top = 1;
        else
            disp(receive_data);
        end
        
    else
        disp(receive_data);
    end
end
end