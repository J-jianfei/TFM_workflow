function [traction_magnitude_selected,roi,energy,avg_energy_density,method,nframes,data_filename_pattern,j,data_file_folder] = findTractionMagnitudeROI(varargin)
    % traction_magnitude_selected follows the structure
    % frameID, traction_magnitude, x, y,
    % roi follows the structure
    % [x1 y1; x2 y1; x2 y2; x1 y2 ...] in counterclockwise order
    % energy is the strain energy in the entire region 
    % and is a row vector having the same length as the number of frames

    [filename,path] = uigetfile('*.mat','Select the TFM output file from TFM_main script');
    load(fullfile(path,filename),"TF_attempt");
    load(fullfile(path,filename),"TF_input");

    crop_roi = TF_input.settings.cropROI;

    manual_selection = 0;
    saveROI = 0;
    filenameWithoutSuffix = extractBefore(filename, '_TFM_output');
    fprintf("Loaded data file name: %s \n",filenameWithoutSuffix);
    
    [imcellname,imcellpath] = uigetfile('*.tif','Select the Cell image(.tif) to select ROI for maximum traction finding');
    if ~exist(fullfile(imcellpath,imcellname), 'file') || isequal(imcellname, 0)
        fprintf('No image is selected, will try to use the entire region \n');
    else
        manual_selection = 1;
        imcell = imread(fullfile(imcellpath,imcellname));
        imcell = imcrop(imcell,crop_roi);
        h = figure;
        if length(size(imcell)) == 2 % grayscale
            imshow(imadjust(mat2gray(imcell)),'Parent',gca(h)); colormap gray;
        elseif length(size(imcell)) == 3 % rgb
            imshow(imcell,'Parent',gca(h))
        end
        % Enable rectangle tool for ROI selection
        % Enable polygon tool for ROI selection
         [roi,~,~] = waitROISelection('polygon','return','backspace',h); 
        issave = questdlg('Do you want to save the ROI?','Save ROI','Yes','No','Yes');
        if strcmp(issave,'Yes')
            saveROI = 1;
        end
    end


    
    prompt = {'Specify the method from which the result are obtained and you want to analyze (B for Bayesian, R for Regularized)', ...
    'Specify the attempt index if you have multiple attempts on that method', ...
    'Specify the frame number for which you want to find the traction magnitudes (0 for finding the magnitudes over all frames)'};
    dims = [1 50];

    userInput = inputdlg(prompt,'Please specify settings to find maximum traction magnitude',dims,{'Regularized','1','0'});

    method = userInput{1};
    j = str2double(userInput{2});



    if strcmpi(method,'Bayesian') || strcmpi(method,'Bay') || strcmpi(method,'B')
        if (~isempty(TF_attempt.Bayesian))
            TFM_results = TF_attempt.Bayesian(j).TFM_results;
            nframes = length(TFM_results);
                for frame = 1:length(TFM_results)
                    x1 = min(TFM_results(frame).pos(:,1));
                    y1 = min(TFM_results(frame).pos(:,2));
                    x2 = max(TFM_results(frame).pos(:,1));
                    y2 = max(TFM_results(frame).pos(:,2));
                    if ~exist("roi","var") 
                        roi = [x1 y1; x2 y1; x2 y2; x1 y2];
                    end
                    energy(frame) = TFM_results(frame).energy;
                    avg_energy_density(frame) = TFM_results(frame).energy / abs((y2 - y1) * (x2 - x1));
                    in_id = find(inpolygon(TFM_results(frame).pos(:,1),TFM_results(frame).pos(:,2),roi(:,1),roi(:,2)));
                    pos_roi = TFM_results(frame).pos(in_id,:);
                    traction_magnitude = TFM_results(frame).traction_magnitude(in_id);
                    traction_magnitude_selected = [frame*ones(length(traction_magnitude),1),traction_magnitude,pos_roi];
                end
            method = 'Bayesian';
        else
                disp('No Bayesian results found in the file');
                return;
        end
    elseif strcmpi(method,'Regularized') || strcmpi(method,'Reg') || strcmpi(method,'R')
        if (~isempty(TF_attempt.Regularized))
            TFM_results = TF_attempt.Regularized(j).TFM_results;
            nframes = TFM_results;
            for frame = 1:length(TFM_results)
                x1 = min(TFM_results(frame).pos(:,1));
                y1 = min(TFM_results(frame).pos(:,2));
                x2 = max(TFM_results(frame).pos(:,1));
                y2 = max(TFM_results(frame).pos(:,2));
                if ~exist("roi","var") 
                    roi = [x1 y1; x2 y1; x2 y2; x1 y2];
                end
                energy(frame) = TFM_results(frame).energy;
                avg_energy_density(frame) = TFM_results(frame).energy / abs((y2 - y1) * (x2 - x1));
                in_id = find(inpolygon(TFM_results(frame).pos(:,1),TFM_results(frame).pos(:,2),roi(:,1),roi(:,2)));
                pos_roi = TFM_results(frame).pos(in_id,:);
                traction_magnitude = TFM_results(frame).traction_magnitude(in_id);
                traction_magnitude_selected = [frame*ones(length(traction_magnitude),1),traction_magnitude,pos_roi];
            end
            method = 'Regularized';
        else
            disp('No Regularized results found in the file');
            return;
        end
    end

    data_filename_pattern = filenameWithoutSuffix;
    data_file_folder = path;
    if(manual_selection && saveROI)
        
        roi_filename = strcat(filenameWithoutSuffix, "_ROI.txt");
        if ~exist(fullfile(path,roi_filename),'file')
            roi_fileId = fopen(fullfile(path,roi_filename),'w');
        else
            roi_fileId = fopen(fullfile(path,roi_filename),'a');
        end
        fprintf(roi_fileId,'Vertices positions: x, y\n');
        fprintf(roi_fileId,'%f, %f\n',roi(:,1),roi(:,2));
        fprintf('ROI is saved as %s \n',roi_filename);
    end

end