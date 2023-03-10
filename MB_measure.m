% The application of this script can be found in Chen et al., iScience,
% 2023. For detailed description, please see Chen et al., Star Protocol,
% 2023.
% The input folder should contain pre-processed images along with n
% excel sheet storing the tilting angle of each sample. The excel sheet
% should be the first file in the folder sorted by name.
% Specify the parameters in the following section according to your
% experimental design and equipment setup.
%% Parameters to be specified.
file_path =  ''; % Specify the directory.
region = '';
staining = {''}; % List the target proteins
mask_ch = ; % Indicate the xth channel as the mask for all channels.
xy_scale = ; %  Pixels/micron
z_step = ; %  micron/step
%%
file_list = dir(file_path); % Get the file list.
num_file = length(file_list); % Number of files.
xy_step = round(1/xy_scale,3); % xy resolution: micron/pixel
num_ch = length(staining) + 1; % Number of channels: number of stainings plus a mask channel.
%%
[angle, genotype] = xlsread(strcat(file_path, file_list(3).name));
    num_sample = sum(~isnan(angle));
    angle = angle(~isnan(angle));
%% 
if sum(num_sample) ~= (num_file - 3)/num_ch % Check if the number of files matches the number of angles.
    fprintf('Missing files or missing angles.')
    return
else
    for gt = 1 : length(genotype)
        data_name{gt} = strcat(genotype{gt}, '_', region);
        temp_data = struct; 
        for sa = sum(num_sample(1 : gt)) - num_sample(gt) + 1 : sum(num_sample(1 : gt))% Read the images of the same sample
           %        
            for ch = 1 : num_ch
                file_name = strcat(file_path,file_list((sa - 1) * num_ch + 3 + ch).name);
                [Stack, xrange, yrange, zrange] = Tiff_stack(file_name,[]);
                value = double(Stack(1 : xrange * yrange * zrange)); % Transform the gray scale matrix into row vectors, and convert to double precision.
                image{ch} = value;
            end
% 
            mask = find(image{mask_ch}); 
% 
            [Y, X, Z] = ind2sub(size(Stack), mask); % Get the xyz coordinates of pixels with non-zero values. X = column; Y = row; Z = frame.
%
            theta = round(angle(sa) + 90); % Rotate the coordinate system theta degree. 
% 
            if theta > 0
                coord_ori = [xy_step * (X - xrange/2); xy_step * (Y - 1); z_step * (Z - zrange)]; % The Z-origin
            else
                coord_ori = [xy_step * (X - xrange/2); xy_step * (Y - 1); z_step * (Z - 1)];
            end
%             
                T = inv([cos(theta * pi/180) sin(theta * pi/180); - sin(theta * pi/180) cos(theta * pi/180)]); % Translation matrix, [y_t z_t]' = T*[y z]'
                yz_ori = coord_ori(2 : 3,:); % Original yz coordinates
                yz_trans = T * yz_ori; % Transformed yz coordiates
                coord_trans = [coord_ori(1,:); yz_trans]; 
%                 
                mask_stack = [coord_trans; mask];
                range = ceil(max(coord_trans,[],2)); % A colume vector, each element corresponds to range of the transformed  stack alone one axis.
                mask_section = mask_stack;
                mask_section(2,:) = ceil(mask_section(2,:)); % Virtual sections along the axis of peduncles (y-axis), 1 micron step;
                sec_num = zeros(range(2),1);
%
                MB_index = []; % Store the indesis of pixels within the array, the first row contains the distance of each pixel along the peduncle axis, the second row contains the indesis of corresponding pixel.
            for dist = 1:range(2) % Virtual sections along the y-axis, in 1-micron steps;
                section = find(mask_stack(2,:) >= dist - 1 & mask_stack(2,:) < dist);
                sec_area(dist) = length(section); % Area is defined as the number of pixels with value greater than 0.
                MB_index = [MB_index, [dist * ones(1,sec_area(dist)); section]]; 
            end
%             
         temp_data(sa - (sum(num_sample(1:gt)) - num_sample(gt))).coordinates = coord_trans;
%            
            integrated = zeros(range(2),num_ch);
            average = integrated;
            area = zeros(range(2),1);
            for ch = 1 : num_ch
                if  ch ~= mask_ch
                    ch_val = image{ch};
                    for dist = 1:range(2) % Section along the axis of peduncles, in 1 micron step;
                        section = find(mask_section(2,:) == dist); % Get the pixels within a virtual section.
                        sec_num(dist) = length(section);
                        sec_val = ch_val(mask_section(4,section)); % Get the values of pixels within a virtual section.
                        integrated(dist,ch) = sum(sec_val); 
                    end 
                average(:,ch) = integrated(:,ch)./sec_num; % Divided by number of pixels with value greater than 0.
                end
            end
            temp_data(sa-(sum(num_sample(1:gt))-num_sample(gt))).integrated = integrated;
            temp_data(sa-(sum(num_sample(1:gt))-num_sample(gt))).average = average;
        end
        eval([data_name{gt} '= temp_data']);
    end 
%     
    save(strcat(region, '_', datestr(now, 'yyyymmdd'), '.mat'), 'genotype', 'staining'); % Save data.
    for gen = 1:length(genotype)
        save(strcat(region, '_', datestr(now, 'yyyymmdd'), '.mat'), data_name{gen}, '-append');
    end
end


