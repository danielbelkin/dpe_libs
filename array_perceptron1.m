classdef array_perceptron1
    properties
        % Want to specify which subarray we're using
        % Need a dpe_writing object
        % Need to save the previous gate voltage, so we can increment
        
        V_gate_set; 
        array_size; % Size of the whole array
        net_size; % Size of the section we're using
        net_corner; % [i j], location of top-right element we're using
        array;
        
    end
    methods
        function obj = array_perceptron1(net_size,net_corner,array_size,V_gate_init)
            nc = [1 1]; as = [128 64]; vg0 = 0.6;
            switch nargin
                case 2
                    nc = net_corner;
                case 3
                    nc = net_corner;
                    as = array_size;
                case 4
                    nc = net_corner;
                    as = array_size;
                    vg0 = V_gate_init;
            end
            
            if net_size+nc>as
                error('Network exceeds array bounds')
            end
            
            
            
            obj.net_size = net_size; 
            obj.array_size = as;
            obj.net_corner = nc;
            obj.V_gate_set = zeros(obj.net_size) + vg0;
            obj.array = dpe_writing();
            obj.array.connect();
        end
        
        function delete(obj)
            obj.array.disconnect();
        end
        
        
        function [obj, weights] = train(obj, data, labels, rate, nreps)
            %
            
            weights = cell(numel(data)*nreps);
            for j = 1:nreps
                for i = 1:numel(data)
                    increment = false(obj.net_size); % Initialize all 0
                    increment(:,labels(i)) = logical(data{i}); % Works only with binary training data
                    [obj, new_weights] = obj.update_weights(increment,rate);
                    weights{(j-1)*numel(data)+i} = new_weights;
                end
            end
        end
        
        function [obj,new_weights] = update_weights(obj, increment,rate)
            % Rate should be near 1?
            %pulse_width = 160e-9; % Fixed?
            V_set = 2.5; % Fixed (make this a property?)
            
            step_size = .01; % V to increment by
            Vg_max = 1.6; % Max gate voltage
            
            increment_fun = @(Vg) rate*step_size*(Vg < Vg_max);
            
            % Create transistor array:
            for i = 1:obj.net_size(1)
                for j = 1:obj.net_size(2)
                    if increment(i,j)
                        obj.V_gate_set(i,j) = obj.V_gate_set(i,j)+increment_fun(obj.V_gate_set(i,j));
                    end
                end
            end 
            V_gate = obj.expand(obj.V_gate_set.*increment);
            V_source = obj.expand(ones(obj.net_size))*V_set; % Voltage applied to each column
            
            % HARDWARE CALLS:
            figure(1); clf; 
            imagesc(V_source)
            colorbar();
            title('Input voltage')
            
            figure(2); clf;
            imagesc(V_gate)
            colorbar();
            title('Gate voltage')
            
            is_ok = input('Go ahead? (y/n)','s');
            if ~strcmpi(is_ok, 'y')
                error('Program interrupted by user')
            end
            
            obj.array.batch_set(V_source,V_gate); % Actually set the weights
            [~, new_weights] = obj.array.batch_read(0.2,2); % Read weights
            
            figure(3); clf;
            imagesc(new_weights(1:4, 1:2)); colorbar;
            title('Weight matrix');
        end
%%        
        function I_out = read_output(obj,V_in)
            V_MAX = 0.2;
            
            a = padarray(V_in,obj.net_corner(1),0,'pre'); % throwaway
            b = padarray(a,obj.array_size(1)-obj.net_corner(1)-obj.net_size(1),0,'post');
            
            raw_V = V_MAX*b/max(b(:));
            
            % HARDWARE CALL:
            figure(1); clf; 
            imagesc(raw_V)
            colorbar();
            title('Read voltage')
            
            is_ok = input('Go ahead? (y/n)','s');
            if ~strcmpi(is_ok, 'y')
                error('Program interrupted by user')
            end
            
            raw_out = obj.array.VMM_hardware(raw_V);
            I_out = raw_out(obj.net_corner(2):obj.net_corner(2)+obj.net_size(2),:);
        end
        
        function [err,stats] = test(obj,data,labels)
            
            outs = obj.read_output(cell2mat(data));
            
            
            ntests = numel(data);
            ranks = zeros(ntests, 1); 
            
            for i=1:ntests
                ranks(i) = sum(outs(:,i) >= out(labels(i))); 
            end
            err = sum(ranks ~= 1)./ntests;
            
            if nargout > 1 % Compute stats
                [~,winners] = max(outs);
                
                ma = zeros(n_out); % Mean Activations
                wc = zeros(n_out); % Win Counts
                for i=1:n_out
                    ma(:,i) = mean(outs(:,labels == i),2)';
                    for j=1:n_out
                        wc(i,j) = sum(winners(:,labels == j) == i)';
                    end
                end
                
                lik = wc./(ones(n_out,1)*sum(wc));
                
                stats.win_counts = wc; % (i,j) is number of times neuron i won for output j
                stats.ranks = ranks; % Rank of the correct answer
                stats.likelihood = lik; % (i,j) = L(label = j|neuron i won) = P(neuron i wins|label j)
                stats.mean_activation = ma; % (i,j) = mean activation of neuron i for label j
                stats.output = outs; % n_out by n_tests matrix holding output voltages
                stats.margins = ma./(ones(length(ma),1)*diag(ma)'); % ratio between activation of correct neuron and activation of other neurons, by digit
                stats.specialization = ma./(diag(ma)*ones(1,length(ma))); % ratio between activation on correct digit and activation on other digits, by neuron
                
            end

        end
        
        
        function c = expand(obj,a)
            % zero-pads array A so that it lines up right
             s = size(a);
%             n_left = obj.net_corner(1)-1; % number to pad on the left
%             n_right = obj.array_size(1) - obj.net_corner(1)-s(1);
%             n_up = obj.net_corner(2)-1;
%             n_down = obj.array_size(2) - obj.net_corner(2)-s(2);
%             
%             b = padarray(a,[n_up n_left],0,'pre');
%             c = padarray(b,[n_down n_right],0,'post');
%             
%             
            c = zeros(obj.array_size);
            c(obj.net_corner(1):obj.net_corner(1)+s(1)-1, obj.net_corner(2):obj.net_corner(2)+s(2)-1) = a;
        end
    end
end


  %%
  %%
