function varargout = findMaxTractionMagnitude(varargin)
    [filename,path] = uigetfile('*.mat','Select the TFM output file from TFM_main script');
    load(fullfile(path,filename),"TF_attempt");
    filenameWithoutSuffix = strrep(filename, '_TFM_output.mat', '');
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
                for frame = 1:length(TF_attempt.Bayesian(j).TFM_results)
                    traction_magnitude = TF_attempt.Bayesian(j).TFM_results(frame).traction_magnitude;
                    [maxTmagAtFrametmp,idxtmp]= max(traction_magnitude(:));
                    maxTmagAtFrame(frame) = maxTmagAtFrametmp(1);
                    idx = idxtmp(1);
                    posmaxAtFrame(frame,:) = TF_attempt.Bayesian(j).TFM_results(frame).pos(idx,:);
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
            for frame = 1:length(TF_attempt.Regularized(j).TFM_results)
                traction_magnitude = TF_attempt.Regularized(j).TFM_results(frame).traction_magnitude;
                [maxTmagAtFrametmp(frame),idxtmp] = max(traction_magnitude(:));
                maxTmagAtFrame(frame) = maxTmagAtFrametmp(1);
                idx = idxtmp(1);
                posmaxAtFrame(frame,:) = TF_attempt.Regularized(j).TFM_results(frame).pos(idx,:);
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
    


end 