classdef sim_array1 < memristor_array
    % Base type: Deterministic, uses a well-defined update function, etc
    % very similar to nonspiking_synapse1
    % In fact, my goal here is pretty much to make nonspiking_synapse1
    % obsolete.
    properties
        net_size
        conductances
        update_fun     % In fact, more sophisticated simulators are just a more sophisticated update_fun
        gmin
        gmax
    end
    methods
%%
        function obj = sim_array1(g0, update_fun, gmin, gmax)
            % Update fun gives ?G as a function of G, V_in, and V_trans
            % pulse width is fixed for now, but number of pulses may
            % eventually be something we can tune.
            
            switch nargin
                case {1 2}
                    error('Not enough input arguments'}
                case 3
                    gmin = 0;
                    gmax = Inf;
                case 4
                    gmax = Inf;
            end
            obj.gmin = gmin;
            obj.gmax = gmax;
            obj.conductances = g0;
            obj.net_size = size(g0);
            obj.update_fun = update_fun;
        end
%%            
        function conductances = read_conductance(obj)
            conductances = obj.conductances;
        end
%%        
        function update_conductance(obj, V_in, V_out, V_trans)
            % I guess I'll also leave V_out fixed grounded for now.
            % Shouldn't need to return obj, now that it's a handle
            if any(V_out) && ~strcmpi(V_out, 'GND')
                warning('Output voltages are fixed at ground')
            end
            
            V_in = obj.expand(V_in);
            V_trans = obj.expand(V_trans);

            for i=1:obj.net_size(1)
                for j=1:obj.net_size(2)
                    g = obj.conductances(i,j);
                    obj.conductances(i,j) = g + obj.update_fun(g,V_in(i,j),V_trans(i,j));
                end
            end  
        end
        
        % Other methods to write: Some sort of testing, probably.
        % Maybe also a "set-weights" type of thing
        
%%        
        function b = expand(obj,a)
            % this function attempts to read minds: Did you mean _ 
            % Does its best to expand things. 
            if all(size(a) == obj.net_size)
                b = a;
            elseif any(size(a) == obj.net_size)
                if iscolumn(a) && length(a) == obj.net_size(1)
                    b = repmat(a,1,obj.net_size(2));
                elseif isrow(a) && length(a) == obj.net_size(2)
                    b = repmat(a,obj.net_size(1),2);
                else
                    error('Not sure how to expand this input')
                end
            elseif isscalar(a)
                b = repmat(a,obj.net_size);
            else
                error('Not sure how to expand this input')
            end
        end
    end
end
       
        
            