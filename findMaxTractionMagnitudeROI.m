function varargout = findMaxTractionMagnitudeROI(varargin)
    [filename,path] = uigetfile('*.mat','Select the TFM output file from TFM_main script');
    load(fullfile(path,filename),"TF_attempt");

    manual_selection = 0;

    
    [imcellname,imcellpath] = uigetfile('*.tif','Select the Cell image(.tif) to select ROI for maximum traction finding');
    if ~exist(fullfile(imcellpath,imcellname), 'file') || isequal(imcellname, 0)
        disp('No image is selected, will try to use the entire region');
    else
        manual_selection = 1;
        imcell = imread(fullfile(imcellpath,imcellname));
        figure, imshow(imadjust(mat2gray(imcell))); colormap gray;
        % Enable rectangle tool for ROI selection
        % Enable polygon tool for ROI selection
        poly = drawpolygon;

        click1 = waitforbuttonpress;
        click2 = waitforbuttonpress;
        if(click1 == 0 && click2 == 0)
            disp('Polygon selection is done');
        end
       

        % Get the final position of the polygon
        roi = poly.Position;

        close(gcf);
    end


    filenameWithoutSuffix = extractBefore(filename, '_TFM_output');
    prompt = {'Specify the method from which the result are obtained and you want to analyze (B for Bayesian, R for Regularized)', ...
    'Specify the attempt index if you have multiple attempts on that method', ...
    'Specify the frame number for which you want to find the maximum traction magnitude (0 for finding the maximum over all frames)'};
    dims = [1 50];

    userInput = inputdlg(prompt,'Please specify settings to find maximum traction magnitude',dims,{'Regularized','1','0'});

    method = userInput{1};
    j = str2double(userInput{2});
    iframe = str2double(userInput{3});


    if strcmpi(method,'Bayesian') || strcmpi(method,'Bay') || strcmpi(method,'B')
        if (~isempty(TF_attempt.Bayesian))
            TFM_results = TF_attempt.Bayesian(j).TFM_results;
                for frame = 1:length(TFM_results)
                    if ~exist("roi","var") 
                        x1 = min(TFM_results(frame).pos(:,1));
                        y1 = min(TFM_results(frame).pos(:,2));
                        x2 = max(TFM_results(frame).pos(:,1));
                        y2 = max(TFM_results(frame).pos(:,2));
                        roi = [x1 y1; x2 y1; x2 y2; x1 y2];
                    end
                    in_id = find(inpolygon(TFM_results(frame).pos(:,1),TFM_results(frame).pos(:,2),roi(:,1),roi(:,2)));
                    traction_magnitude = TFM_results(frame).traction_magnitude(in_id);
                    [maxTmagAtFrametmp,idxtmp]= max(traction_magnitude(:));
                    maxTmagAtFrame(frame) = maxTmagAtFrametmp(1);
                    idx = idxtmp(1);
                    posmaxAtFrame(frame,:) = TFM_results(frame).pos(in_id(idx),:);
                end
                
                if iframe == 0
                    [maxTmagtmp,idxtmp] = max(maxTmagAtFrame);
                    maxTmag = maxTmagtmp(1);
                    idx = idxtmp(1);
                    posmax = posmaxAtFrame(idx,:);
                else
                    maxTmag = maxTmagAtFrame(iframe);
                    posmax = posmaxAtFrame(iframe,:);
                end
            method = 'Bayesian';
        else
                disp('No Bayesian results found in the file');
                return;
        end
    elseif strcmpi(method,'Regularized') || strcmpi(method,'Reg') || strcmpi(method,'R')
        if (~isempty(TF_attempt.Regularized))
            TFM_results = TF_attempt.Regularized(j).TFM_results;
            for frame = 1:length(TFM_results)
                if ~exist("roi","var") 
                    x1 = min(TFM_results(frame).pos(:,1));
                    y1 = min(TFM_results(frame).pos(:,2));
                    x2 = max(TFM_results(frame).pos(:,1));
                    y2 = max(TFM_results(frame).pos(:,2));
                    roi = [x1 y1; x2 y1; x2 y2; x1 y2];
                end
                traction_magnitude = TFM_results(frame).traction_magnitude;
                in_id = find(inpolygon(TFM_results(frame).pos(:,1),TFM_results(frame).pos(:,2),roi(:,1),roi(:,2)));
                [maxTmagAtFrametmp(frame),idxtmp] = max(traction_magnitude(in_id));
                maxTmagAtFrame(frame) = maxTmagAtFrametmp(1);
                idx = idxtmp(1);
                posmaxAtFrame(frame,:) = TF_attempt.Regularized(j).TFM_results(frame).pos(in_id(idx),:);
            end
            if iframe == 0
                [maxTmagtmp,idxtmp] = max(maxTmagAtFrame);
                maxTmag = maxTmagtmp(1);
                idx = idxtmp(1);
                posmax = posmaxAtFrame(idx,:);
            else
                maxTmag = maxTmagAtFrame(iframe);
                posmax = posmaxAtFrame(iframe,:);
            end
            method = 'Regularized';
        else
            disp('No Regularized results found in the file');
            return;
        end
    end


    disp(['Maximum traction magnitude with spefied settings is ', num2str(maxTmag), ...
        ' at position  x ', num2str(posmax(1)),' y ', num2str(posmax(2))]);


    [savename,savepath] = uiputfile('*.txt','Save the results');
    if ~exist(fullfile(savepath,savename),'file')
        fileID = fopen(fullfile(savepath,savename),'w');
        fprintf(fileID,'Data filename, Maximum traction magnitude (Pa), x position (pix), y position (pix), frame, attemptId, TF method\n');
        fprintf(fileID,'%s, %f, %f, %f, %d, %d, %s \n',filenameWithoutSuffix,maxTmag,posmax(1),posmax(2),iframe,j,method);
    else
        fileID = fopen(fullfile(savepath,savename),'a');
        fprintf(fileID,'%s, %f, %f, %f, %d, %d, %s \n',filenameWithoutSuffix,maxTmag,posmax(1),posmax(2),iframe,j,method);
    end
    
    fclose(fileID);

    if(manual_selection)
        
        roi_filename = strcat(filenameWithoutSuffix, "_ROI.txt");
       % if ~exist(fullfile(savepath,roi_filename),'file')
            roi_fileId = fopen(fullfile(savepath,roi_filename),'w');
            fprintf(roi_fileId,'Vertices positions: x, y\n');
            fprintf(roi_fileId,'%f, %f\n',roi(:,1),roi(:,2));
            fclose(roi_fileId);
        % end
    end

end 