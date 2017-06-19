classdef (Abstract) memristor_array < handle
    % The purpose of this is just to be able to test identical training
    % protocols on real and simulated arrays.
    % Additionally, could be applied to simulations of various styles, or
    % various types of memristors, etc
    
    properties (Abstract)
        net_size % I think this is the only one that all need
    end
    methods (Abstract)
        conductances = read_conductance(obj, varargin)
            % Could read some or all
            % Is it a safe bet that the object won't need updating?
        update_conductance(obj, V_in, V_out, V_trans)
            % I guess this is sufficient?
            % In fact, I suppose V_out is fixed at 0 always.
            % This may need to change, though.
            
        % A test() method will also be needed, I suspect - TODO
       
        
        % If I want this to inherit from handle, then I also should maybe
        % write a delete method - TODO?
    end
end


% Ok, thing I haven't thought about: We really only want to have to
% simulate small subsections of the array, not all 128x64. Should we plan
% to ignore the unused region? Should this superclass have an array size?
%
% Ok, goal: Separate training protocol and hardware/simware
% training is handled by "perceptron" or "layer" class
% communication (expansion, calculation of v_trans) and/or simulation is
% handled by "array" class
%
% This is going to involve a good bit of restructuring, but that's ok. 
% Additionally, I'm not sure how best to simulate transistor behavior, but
% that's a concern for another time.