classdef array_perceptron2
    % Training strategy: Save transistor voltage externally and increment
    % seqeuentially.
    % This is not a very good strategy.
    % I am writing this mostly because I want a version that can interface
    % with the memristor_array superclass.
    
    properties
        V_gate_set; % Need to save the previous gate voltage, so we can increment
        array;
    end
    methods
        function obj = array_perceptron2(array,Vg0)
            % Array must be initialized externally
            % Vg0 defaults to 0
            
            if nargin < 2
                Vg0 = 0;
            end
            
            obj.V_gate_set = zeros(net_size) + Vg0;
            obj.array = array;
            
            % Additionally, want to initialize all elements to the correct
            % resistance state.
            % Will have to handle that later.
            
        end
        
        function delete(obj)
            obj.array.delete();
        end
        
        
        function [obj, weights] = train(obj, data, labels, rate, nreps)
            % Weights is a cell array tracking weight evolution
            % Actually, weights tracks the full array, not just the area in
            % use.
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
            % Increment is a logical matrix, of the same size as the object
            % Rate defaults to .01, and is the amount by which V_trans is
            % incremented each time.
            %pulse_width = 160e-9; % Fixed, it seems
            
            if nargin < 3
                rate = .01;
            end
            
            V_set = 2.5; % Fixed (make this a property?)
            
            Vg_max = 1.6; % Max gate voltage
            
            increment_fun = @(Vg) rate*(Vg < Vg_max); % Determines the size of the step
            
            for i = 1:obj.net_size(1)
                for j = 1:obj.net_size(2)
                    if increment(i,j)
                        obj.V_gate_set(i,j) = obj.V_gate_set(i,j)+increment_fun(obj.V_gate_set(i,j));
                    end
                end
            end 
            V_gate = obj.V_gate_set.*increment; % Apply it only if it has been incremented
            % Seems very sketchy to me, talk to Can about changing this
            % part of the training protocol
            
            obj.array.update_conductance(V_set,'GND',V_gate);
            new_weights = obj.array.read_conductance();
        end
%%        
% At some point, I will need to write testing functions
% It may be useful to have both a sim_test(), using known weights, and a
% test() that interfaces with the actual array?
    end
end