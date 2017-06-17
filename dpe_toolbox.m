classdef dpe_toolbox < handle
    properties
        n_xbar
        n_dct
        
        n_pic
        
        fitting_a
        fitting_b
        fitting_r 
        
        image_shift
        
        bad_cols
    end

    methods(Static)
        function image_out = expandVIN(image_in, col_start, col_total)
            image_out = zeros( size(image_in, 1), col_total);
            for j= 1: size(image_in, 2)
                if j + col_start - 1 <= col_total
                    image_out(:,  j + col_start - 1) = image_in(:, j);
                end
            end
        end
    end
    
    methods
        function obj = dpe_toolbox(n_xbar, n_dct)
        % DPE_TOOLBOX
            obj.n_xbar = n_xbar;
            obj.n_dct = n_dct;
%             obj.dct = dctmtx(n_dct);
        end


        % THESE functions are the call back functions to process the images
        
        function image_out = image_copy(~, image_in, ~)
            image_out = image_in;
        end
        
        function image_out = transpose_normalize(obj, image_in, i)
            obj.image_shift(i) = mean(image_in(:));
            image_out = image_in.' - obj.image_shift(i);
        end
        
        function image_out = recover_normalize(obj, image_in, i)
            image_out = image_in.' + obj.image_shift(i);
        end
        
        function image_out = recover_idct(obj, image_in, i)
            image_out = idct( image_in.') + obj.image_shift(i) ;
        end
        
        function image_out = recover_transpose_idct(obj, image_in, i)
            image_out = idct( image_in) + obj.image_shift(i) ;
        end
        
        function image_out = recover_2didct(obj, image_in, i)
            image_out = idct( idct( image_in.')') + obj.image_shift(i) ;
        end
        
        function image_out = image_2ddct(~, image_in, ~)
            image_out = dct2( image_in).';
        end

        function image = image_to_multirows(obj, image_in, processCallback)
        % IMAGE_TO_MULTIROWS convert the images block by block and stack blocks into rows.
        % Shift images DC component to make mean value of zero
        %
        % @input Image_in: Oringal image to be processed
        % @input processCallback: the callback functon to process each
        % block of the images.
        
            obj.n_pic = size(image_in);
            obj.n_pic(1) = floor(obj.n_pic(1) / obj.n_dct); %rows
            obj.n_pic(2) = floor(obj.n_pic(2) / obj.n_dct); %cols

            image = zeros(obj.n_pic(1)*obj.n_pic(2)*obj.n_dct, obj.n_dct);
            obj.image_shift = zeros( obj.n_pic(1) * obj.n_pic(2), 1 );

            for i = 1:obj.n_pic(1)
                for j = 1:obj.n_pic(2)
                    image_tmp = image_in( (i-1) * obj.n_dct +1: i*obj.n_dct, (j-1) * obj.n_dct +1: j*obj.n_dct);
                    image_tmp = processCallback( image_tmp, (i-1)*obj.n_pic(2) +j);
                    
                    image( ((i-1) * obj.n_pic(2) + (j-1) )*obj.n_dct + 1: ((i-1) * obj.n_pic(2) + (j) )*obj.n_dct, 1:obj.n_dct) = ...
                        image_tmp;
                end
            end
        end
        
        
        
        function image = multirows_to_image(obj, image_in, processCallback)
        % MULTIROWS_TO_IMAGE recover the stacked row images.
        % @input Image_in: Oringal image to be processed
        
            n_tmp = obj.n_dct;
            image = zeros(obj.n_pic(1)*n_tmp, obj.n_pic(2)*n_tmp);

            for j=1:obj.n_pic(1)*obj.n_pic(2)
                row = floor( (j-1) /obj.n_pic(2)) +1;
                col = j - (row-1) * obj.n_pic(2);
                
                image_tmp = image_in( (j-1)*n_tmp +1: j*n_tmp, 1:n_tmp );
                image_tmp = processCallback( image_tmp, j );
                
                image( (row -1) * n_tmp +1: row*n_tmp, (col-1)*n_tmp +1: col*n_tmp) = ...
                    image_tmp;
            end
        end
        
        function image = imageblock_from_multirows(obj, image_in, j, processCallback)
            n_tmp = obj.n_dct;
            
            image = processCallback( image_in( (j-1)*n_tmp +1: j*n_tmp, 1:n_tmp ) );
        end
        
         % TEMPERAY FUNCTION to be generalized
        function image = image_to_overlap_multirows(obj, image_in, block_size, processCallback )
            n_tmp = obj.n_dct;

            obj.n_pic = size(image_in);
            
            obj.n_pic(1) = size(image_in, 1) / block_size;
            obj.n_pic(2) = size(image_in, 2) / block_size;
            
            image = zeros(obj.n_pic(1)*obj.n_pic(2)*obj.n_dct, obj.n_dct);
            obj.image_shift = zeros( obj.n_pic(1) * obj.n_pic(2), 1 );
            
            for i = 1:obj.n_pic(1)
                for j = 1:obj.n_pic(2)
                    image_tmp = image_in( (i-1) * block_size +1: i*block_size, (j-1) * block_size +1: j*block_size);
                    image_tmp = processCallback( image_tmp, (i-1)*obj.n_pic(2) +j);
                    
                    image_tmp_filled = mean(image_tmp(:)) * ones(n_tmp, n_tmp);
                    image_tmp_filled( n_tmp - block_size + 1: n_tmp, n_tmp - block_size + 1: n_tmp ) = image_tmp;
                    
                    image( ((i-1) * obj.n_pic(2) + (j-1) )*obj.n_dct + 1: ((i-1) * obj.n_pic(2) + (j) )*obj.n_dct, 1:obj.n_dct) = ...
                        image_tmp_filled;
                end
            end
        end
       
        function image = overlap_remove(obj, image_in, block_size)
        
            n_tmp = obj.n_dct;
            image = zeros(obj.n_pic(1)*block_size, obj.n_pic(2)*block_size);
            
            for i = 1:obj.n_pic(1)
                for j = 1:obj.n_pic(2)
                    image_tmp = image_in( (i-1) * n_tmp +1: i*n_tmp, (j-1) * n_tmp +1: j*n_tmp);
                    
                    
                    image( (i-1) * block_size +1: i*block_size, (j-1) * block_size +1: j*block_size) = ...
                        image_tmp( n_tmp - block_size + 1: n_tmp, n_tmp - block_size + 1: n_tmp );
                end
            end
        end

       
        
        function image = multirows_rotate(obj, image_in)
            n_tmp = obj.n_dct;
            image = image_in;

            for j=1:obj.n_pic(1)*obj.n_pic(2)
            
                image( (j-1)*n_tmp +1: j*n_tmp, 1:n_tmp ) = image_in( (j-1)*n_tmp +1: j*n_tmp, 1:n_tmp ).';
            end
        end
        
        
        function remap = remap(~, Mout, Min1, Min2)
            % REMAP remap the linear mapped dot product results.
            
            remap = Mout / Min1.alpha / Min2.alpha;
            remap = remap - size(Mout, 2) * Min1.shift * Min2.shift / Min1.alpha / Min2.alpha * ones(size(Mout));
            
            remap = remap - Min1.shift / Min1.alpha * repmat( sum(Min2.M_ori, 1), size(Min1.M_ori, 1) ,1 );
            remap = remap - Min2.shift / Min2.alpha * repmat( sum(Min1.M_ori, 2), 1, size(Min2.M_ori, 2) );
        end
        
        function average = average(~, dpe_output_M, start_i)
            average = zeros(size(dpe_output_M(:,:,1)));

%             figure;
            average_n = 0;
            for i = start_i : size(dpe_output_M,3) 
                average_n = average_n +1;
%                 subplot(2,3,i);
%                 imagesc(dpe_output_M(:,:,i) );
%                 title(['DPE output: layer ' num2str(i)]);
%                 colorbar;

                average = average + dpe_output_M(:,:,i);
            end
            
            average = average / average_n;
            
%             subplot(2,3,6);
%             imagesc(average );
%             title('DPE output: Average ');
%             colorbar;
        end
        
        function dpe_output_1_corrected = correct_from_fitting(obj, dpe_output_1_average, threshold)
            %CORRECT_FROM_FITTING correct input matrix based on the
            %linear correction parameters store in the class. 
            if nargin < 3  
                threshold = 999; %max value
            end
            
            dpe_output_1_corrected = zeros(size(dpe_output_1_average));
            disp(['using fitting a=' num2str(obj.fitting_a) ' b=' num2str(obj.fitting_b)]);
            
            disp(['              r=' num2str(obj.fitting_r)]);
            
            for j = 1: size(dpe_output_1_average, 1)
                ydata = dpe_output_1_average(j,:);

                for i = 1: size(dpe_output_1_average, 2)
                    if ( abs( ydata(i) ) > threshold)
                        ydata(i) = 999;
                    else
                        ydata(i) = ydata(i) * obj.fitting_a(i) + obj.fitting_b(i);
                    end
                end

                dpe_output_1_corrected(j,:) = ydata;
            end
        end
        
        function set_correction_parameter(obj, fitting_a, fitting_b)
            %SET_CORRECTION_PARAMETER direct assigan correction parameters
            
            obj.fitting_a = fitting_a;
            obj.fitting_b = fitting_b;
        end
        
        function image = image_add(obj, image_in)
            image = zeros( size(image_in, 1) /2, size(image_in, 2) );
            
            n = size(image_in, 1) / obj.n_dct /2;
            for i = 1:n
                image( (i-1)*obj.n_dct +1:  i*obj.n_dct, :) = ...
                    image_in( (i-1)*2 *obj.n_dct +1:  ((i-1)*2+1) *obj.n_dct, : ) + ...
                    image_in( ((i-1)*2+1) *obj.n_dct +1:  (i*2) * obj.n_dct, : );
            end
        end
        
        function fit_correction_parameter(obj, dpe_output, dpe_output_expected, threshold)
            % FIT_CORRECTION_PARAMETER did fitting and store the correction
            % parameter in the class implementation
            if nargin < 4  
                threshold = 999; %max value
            end
                
            
            linearfittype = fittype({'x','1'});
            
            if size(dpe_output) ~= size(dpe_output_expected)
                display('Matrix size mismatch');
                return
            end
  
            n_col = size(dpe_output_expected, 2);
            
            obj.fitting_a = zeros(1, n_col );
            obj.fitting_b = zeros(1, n_col );
            
             fitting_col = 1:n_col;
            for j = 1:n_col
                output = dpe_output(:, j);
                expect = dpe_output_expected(:, j);
                
                expect( abs(output) > threshold ) = [];
                output( abs(output) > threshold ) = [];
                
                [f, gof] = fit( output, expect,  linearfittype);
                obj.fitting_a(1,j) = f.a;
                obj.fitting_b(1,j) = f.b;
                obj.fitting_r(1,j) = gof.rsquare;
            end

            figure(11);
            subplot(3,1,1);
            scatter(fitting_col, obj.fitting_a);
            xlabel('Column number');
            ylabel('fitted a');

            subplot(3,1,2);
            scatter(fitting_col, obj.fitting_b);
            xlabel('Column number');
            ylabel('fitted b');
            
            subplot(3,1,3);
            scatter(fitting_col, obj.fitting_r);
            xlabel('Column number');
            ylabel('fitted r');
%             ylim([0.95 1]);
        end
        
        function fitting_compare(~, dpe_output, dpe_output_expected, cols)
            figure(16);
            hold on;
            xlabel('Expected current (mA)');
            ylabel('DPE output (mA)');

            for j = cols
                scatter(dpe_output_expected(:, j)*1e3, dpe_output(:, j)*1e3, 3);
            end
        end
        
        function image = recover_bad_cols(obj, image_in )
%             bad_cols = obj.bad_cols;
            
            image = [];
            image_bad = [];
            
%             i_to = 1;
            for i_from = 1:obj.n_xbar
                if any( obj.bad_cols == i_from)    
                    image_bad = [image_in(:, i_from) image_bad];
                else
                    image = [image image_in(:, i_from) ];
                end
            end
            
            image = [image image_bad];
        end
        
        function image = move_bad_cols(obj, image_in, bad_cols)
            obj.bad_cols = bad_cols;
            
            i_from = 1;
            i_from_r = 64;
            
            image = zeros(size(image_in));
            for i_to = 1: obj.n_xbar
                if any( bad_cols == i_to)
                    image(:,i_to) = image_in(:,i_from_r);
                    i_from_r = i_from_r - 1;
                else
                     image(:,i_to) = image_in(:,i_from);
                     i_from = i_from + 1;
                end
            end
            
        end
    end

end