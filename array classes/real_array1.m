classdef real_array1 < memristor_array
    % The class for real crossbars, version 1
    % This class uses a specified subsection of the crossbar, and does
    % nothing to anything devices outside the subsection
    
    % TODO: add strict maxima
    properties
        array_size
        net_size
        net_corner
        array
    end
    methods
%%
        function obj = real_array1(net_size,array_size,net_corner)
            % Size is n_in by n_out
            nc = [1 1]; as = [128 64]; % defaults
            switch nargin
                case 1
                    error('Network size must be specified')
                case 2
                    as = array_size;
                case 3
                    nc = net_corner;
                    as = array_size;
            end
            
            if any(net_size+nc>as)
                error('Network exceeds array bounds')
            end
            
            obj.net_size = net_size; 
            obj.array_size = as;
            obj.net_corner = nc;
            obj.array_size = array_size;
            
            obj.array = dpe_writing();
            obj.array.connect();
        end
%%        
        function delete(obj)
            obj.array.disconnect();
        end
%%        
        function conductances = read_conductance(obj, varargin)
            % G = OBJ.READ_CONDUCTANCE() reads all conductances in the
            % array and returns them as a matrix.
            % G = OBJ.READ_CONDUCTANCE('NAME',VALUE) controls parameters
            % for the read operation
            % Optional args:
            %   'v_read' = 0.2
            %   'gain' = 2
            % We would like the ability to read only the
            % desired subarray, without having to take the time to read the
            % whole thing - TODO (talk to Can about how)
            
            okargs = {'v_read' 'gain'};
            defaults = {0.2 2};
            [V_read, gain] = internal.stats.parseArgs(okargs,defaults,varargin{:});
            [~, conductances] = obj.array.batch_read(V_read,gain); % HARDWARE CALL
        end
%%        
        function update_conductance(obj, V_in, V_out, V_trans)
            % V_in can be a scalar, a column vector of length net_size(1),  
            % or a matrix of size net_size
            % V_trans should probably be a matrix of size net_size or a scalar (for now)
            % V_out doesn't matter, leave it at 'GND'
            
            % There is a balance to be struck here between generalizability
            % and usefulness 
            if any(V_out) && ~strcmpi(V_out, 'GND')
                warning('Output voltages are fixed at ground')
            end
            
            V_gate = obj.expand(V_trans);
            V_source = obj.expand(V_in)*V_set; % Voltage applied to each column
            
            obj.array.batch_set(V_source,V_gate); % HARDWARE CALL
            
        end
%%        
        function c = expand(~,a,x)
            % B = OBJ.EXPAND(A) zero-pads array A so that it lines up right
            % with the object matrix.
            % B = OBJ.EXPAND(A,X), where X is a scalar, pads with X
            % instead.
            
            % First part: Expand a to net_size
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
            
                        
            % Second part: Pad b to array_size
            if nargin<3
                x = 0;
            end
            s = obj.net_size;
            
            c = zeros(obj.array_size)+x;
            c(obj.net_corner(1):obj.net_corner(1)+s(1)-1, obj.net_corner(2):obj.net_corner(2)+s(2)-1) = b;
        end
    end
end
     
        
% I may want functions to:
%   Initialize all conductances to some desired value
%   Bring a subset of conductances to some desired value
%   Read a subset of conductances (definitely want this, TODO)
% 

% In fact, it may eventually be useful to rewrite this so that it interacts
% more directly with the device, instead of going through these layers of
% abstraction... consider it.