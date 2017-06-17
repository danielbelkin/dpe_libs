 classdef mapped_matrix < handle
    properties
        M_ori
        M_mapped
        M_diff

        alpha %scalling factor
        shift %shift
    end
    methods
        function obj = mapped_matrix(M_ori, M_range, mode)
        % MAPPED_MATRIX construct function
            obj.M_ori = M_ori;
            
            M_min = M_range(1);
            M_max = M_range(2);
            
            n = size(obj.M_ori);

            if nargin == 2  
                mode = 1;
            end
                
            switch mode 
                case 0 % negative
            
                    obj.alpha = -(M_max - M_min) / ( max(M_ori(:)) - min(M_ori(:)) ) ; %scaling factor
                    obj.shift = M_min + obj.alpha * min(M_ori(:)); %shift

                    obj.M_mapped = obj.alpha * M_ori + obj.shift;
                case 1 % normal
            
                    obj.alpha = (M_max - M_min) / ( max(M_ori(:)) - min(M_ori(:)) ) ; %scaling factor
                    obj.shift = M_min - obj.alpha * min(M_ori(:)); %shift

                    obj.M_mapped = obj.alpha * M_ori + obj.shift;
                case 2 % zeroshift
                    obj.shift = 0;
                    
                    To_range = min( abs(M_range ) );
                    From_range = max(max( abs(M_ori)));

                    obj.alpha = To_range / From_range;
                    obj.M_mapped = obj.alpha * M_ori;
                    
                case {3, 4, 5, 6} % differential pair
                    Mmax = max( abs(M_ori(:) ) );
                    obj.alpha = 2 * (M_max - M_min) / ( 2 * Mmax ); %scaling factor     
                    
                    obj.M_mapped = obj.alpha * M_ori;   
                    
                    mid = (M_min + M_max) / 2;
                    
                    switch mode
                        case 3
                            % Altogether
                            obj.M_diff = zeros( n(1), n(2) * 2);
                            obj.M_diff(:, 1: n(2)) = M_ori * obj.alpha / 2 + mid;
                            obj.M_diff(:, n(2)+1: n(2)*2) = - M_ori * obj.alpha / 2 + mid;
                        case 4
                            % part by part software add uyp
                            obj.M_diff = zeros( n(1)*2, n(2) * 2);
                            obj.M_diff(1: n(1), 1: n(2)) = M_ori * obj.alpha / 2 + mid;
                            obj.M_diff(n(1)+1: n(1)*2, n(2)+1: n(2)*2) = - M_ori * obj.alpha / 2 + mid;
                        case 5
                            % line by line
                            obj.M_diff = zeros( n(1), n(2) * 2);
                            obj.M_diff(:, 1:2:end) = M_ori * obj.alpha / 2 + mid;
                            obj.M_diff(:, 2:2:end) =  - M_ori * obj.alpha / 2 + mid;
                        case 6
                            % line by line software add up
                            obj.M_diff = zeros( n(1) *2, n(2) * 2);
                            obj.M_diff(1: n(1), 1:2:end) = M_ori * obj.alpha / 2 + mid;
                            obj.M_diff(n(1)+1: n(1)*2, 2:2:end) =  - M_ori * obj.alpha / 2 + mid;
                    end
                    
                case 7 % zeroshift for DFT
%                     obj.M_ori = M_ori;
                    obj.M_ori = zeros( size(M_ori) * 2 );
                    obj.M_ori(1:2:end, 1:size(M_ori,2) ) = M_ori;
                    obj.M_ori(2:2:end, size(M_ori,2)+1: size(M_ori,2)*2) = M_ori;
                    
                    obj.shift = 0;
                    
                    To_range = min( abs(M_range ) );
                    From_range = max(max( abs(obj.M_ori)));

                    obj.alpha = To_range / From_range;
                    obj.M_mapped = obj.alpha * obj.M_ori;
            end
                  
        end
        
        function zero_shift(obj, M_range)
            obj.shift = 0;
            To_range = min( abs(M_range ) );
            From_range = max(max( abs(obj.M_ori)));
            
            obj.alpha = To_range / From_range;
            obj.M_mapped = obj.alpha * obj.M_ori;
        end
    end
end