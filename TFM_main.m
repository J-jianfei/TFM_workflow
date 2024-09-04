function TFM_main()

fprintf("Welcome to the TFM analysis script.\n" + ...
    "This script is to process a full workflow of Traction Force Microscopy data.\n" + ...
    "The workflow consists of image stack alignment, cropping,\n" + ...
    "beads detection, tracking, and traction field calculation.\n" + ...
    "and traction field calculation.\n" );

fprintf("To start, select a working directoy where the data is stored.\n");

%% change to working directory
workingDir = uigetdir('Select a working directory');
if isequal(workingDir,0) || isempty(workingDir)
    error('No directory selected. Exiting...');
end
cd(workingDir);

warning('off','all');

fprintf("IMPORTANT! Usage is strictly limited to specific keys and data types. \n" + ...
    "Please only refer to the text shown in command window. \n" + ...
    "Note that all warning messages are suppressed, it might be hard \n" + ...
    "to position the potential problem from unexpected inputs. \n");

%% initialize some variables
status = 'idle';
previous_status = 'none';

process_status = {'loadImg','correctDrift','cropImage','enhanceContrast','pointDetection',...
    'pointTracking','tractionCalculation'};


nrows = 0; ncols = 0; nframes = 0;
imgCondition = 'Raw';
filename =[];
pathname = [];

lastDefaultImgCondition = {};
lastDefaultReferenceForDriftCorrection = 1;
lastDefaultDof = {};
lastDefaultPointDetection={};
lastDefaultPointTracking={};

settings = struct;
%% main processing loop, capable for processing multiple files manually, no need to exit the script.
% However, batch processing is not supported yet.

while true

    % record last process status in case that the user types wrong commands
    % allow the user to go back to the previous step

    switch status
        case 'idle'
            [status] = checkIdleCommand();
            continue;
        case 'exit'
            disp('Exit the TFM full workflow...')
            break;
        case 'loadImg'
            [imstack,status] = loadImg(imgCondition);
            imstack_loaded = imstack; % make a copy to save imported image stack
            nframes = size(imstack,3);
            ncols = size(imstack,2);
            nrows = size(imstack,1);

            continue;
        case 'correctDrift'
            [imstack_aligned,roi_driftcorrection,...
                lastDefaultReferenceForDriftCorrection,hview] = driftCorrection(lastDefaultReferenceForDriftCorrection);
            settings.driftCorrectionROI = roi_driftcorrection;
            imstack = imstack_aligned; 
            clearvars imstack_aligned;
        case 'cropImage' 
            % crop images to exclude potental black boarders due to alignment
            % if the drift is too large

           
            [imstack_aligned_cropped,roi_crop,hview] = cropAlignedImstack();

            imstack = imstack_aligned_cropped;
            settings.cropROI = roi_crop;

            clearvars imstack_aligned_cropped;
        case 'enhanceContrast'
            
            [imstack_filtered,lastDefaultDof,sigma1,sigma2,hview] = applyDifferenceOfGaussianFilter(lastDefaultDof);
            settings.sigma1 = sigma1;
            settings.sigma2 = sigma2;
            imstack = imstack_filtered;
            
            clearvars imstack_filtered;

        case 'pointDetection'
            [points,lastDefaultPointDetection,minQuality,filterSize,hview] = ...
                detectPointsAtRerenceFrame(lastDefaultPointDetection);
            settings.minQuality = minQuality;
            settings.filterSize = filterSize;
        case 'pointTracking'
            [input_data,lastDefaultPointTracking,blksz,maxBidirectionalError, ...
            numPyramidLevels,hview] = pointTracking(lastDefaultPointTracking);
            settings.maxBidirectionalError = maxBidirectionalError;
            settings.blockSize = blksz;
            settings.numPyramidLevels = numPyramidLevels;
        case 'tractionCalculation'
            disp('start calculate tracion, creating a temporary folder...');
            tempdir = "temp_dir";
            if ~exist("tempdir","dir")
                mkdir("temp_dir")
            end

            disp('entering temporary folder...')
            cd(tempdir)
            save(strcat(filename(1:end-4),"_TFM_Input.mat"),"input_data");
            disp('Choose the saved TFM input file to perform further calculation')
            disp('Otherwise the script will abort')
            disp('DONOT CHANGE THE DEFAULT OUTPUT FILENAME OF TFM SOFTWARE!')
            TF_reconstruction;
            % have to update status here to postpone the script.
            status = checkWorkFlowCommand(status);
            % Check for files matching the pattern "Bay-FTTC*.mat"
            files_bay = dir('Bay-FTTC*.mat');
            % Check for files matching the pattern "Reg-FTTC*.mat"
            files_reg = dir('Reg-FTTC*.mat');
            % Check if any files were found
            if ~isempty(files_bay) || ~isempty(files_reg)
                % Display the matching files
                for id_attempt = 1:length(files_bay)
                    attempt_bay(id_attempt) = load(files_bay(id_attempt).name);
                end
                
                for id_attempt = 1:length(files_reg)
                    attempt_reg(id_attempt) = load(files_reg(id_attempt).name);
                end
            else
                disp('No matching files found in the current folder, TF_recontruction might exit wrongly.');
            end
            disp('exit the temporary folder');
            cd ../;
            rmdir(tempdir,'s');
            clearvars files_reg files_bay temp_dir
            continue;
        case 'saveData'
            savefullname = fullfile(pathname,strcat(filename(1:end-4),'_TFM_output.mat'));
            % Save the data
            [savefilename, savepathname] = uiputfile(savefullname, 'Save the data');
            if isequal(savefilename,0)
                fprintf('No file selected. Please Enter filename manually. \n');
                status = 'saveData';
                continue;
            end
            TF_attempt = struct('Bayesian', [], 'Regularized', []);
            if exist("attempt_bay","var")
                TF_attempt.Bayesian = attempt_bay;
            end
            if exist("attempt_reg","var")
                TF_attempt.Regularized = attempt_reg;
            end
            TF_input = struct('settings', settings, 'TFM_input_data', input_data);
            save(fullfile(savepathname, savefilename), 'TF_attempt', 'TF_input');
            fprintf('Data saved successfully. \n ');
            fprintf(['Image processing and displacement measurement settings \n '...
                'are saved in the variable "TF_input" in the filed "settings" \n' ...
                'displacement fields are saved in the variable "TF_input" in the field "TFM_input_data" \n' ...
                'TFM results are saved in the variable "TF_attempt" in fields "Bayesian" and "Regularized". \n' ...
                'In each field, the results and settings are saved as "TFM_results" and "TFM_settings" \n']);  
            status = 'idle';

            clearvars -except status  lastDefaultPointTracking lastDefaultPointDetection ...
                lastDefaultPointTracking lastDefaultDof lastDefaultReferenceForDriftCorrection ...
                lastDefaultImgCondition nframes ncols nrows process_status previous_status
            nrows = 0; ncols = 0; nframes = 0;
            settings = struct;
            continue;

    end

    status = checkWorkFlowCommand(status);
    if exist("hview","var")
        if isvalid(hview)
            close(hview)
        end
    end
end



    function [nextStatus] = checkWorkFlowCommand(currentStatus)
        nextStatus = 'idle';
        if ismember(currentStatus,process_status)
            statusId = find(ismember(process_status,currentStatus));
            % check workflow commands
            userDecision = input('Type continue (c) to proceed, redo (r) to redo current session: ','s');
            if strcmpi(userDecision,'continue') || strcmpi(userDecision,'c') || strcmpi(userDecision,'')
                if statusId == length(process_status)
                    nextStatus = 'saveData';
                else
                    nextStatus = process_status{statusId + 1};
                end
            elseif strcmpi(userDecision,'redo')|| strcmpi(userDecision,'r')
                nextStatus = process_status{statusId};
            end
            previous_status = currentStatus;
        else
            fprintf('Input command is not recognized, please try again...\n');
        end
    end

    function [imgCondition,newDefault] = askInputImageCondition(defaultImgCondition)
        
        prompt = {'Is the image stack aligned?', 'Is the image stack aligned and cropped?',...
            'Is the image stack enhanced?'};
        dlgtitle = 'Does the image stack fulfill the requirements? (1 for yes, 0 for no)';
        dims = [1 100];
        if nargin == 0 || isempty(defaultImgCondition)
            default = {'0', '0','0','0'};
        else
            default = defaultImgCondition;
        end
        userInput = inputdlg(prompt, dlgtitle,dims,default);
        isAligned = str2double(userInput{1});
        isCropped = str2double(userInput{2});
        isEnhanced = str2double(userInput{3});
        
        newDefault = userInput;
        
        if isAligned == 1 && isCropped == 1 && isEnhanced == 1
            imgCondition = 'Enhanced';
        elseif isAligned == 1 && isCropped == 1 && isEnhanced == 0
            imgCondition = 'Aligned&cropped';
        elseif isAligned == 1 && isCropped == 0 && isEnhanced == 0
            imgCondition = 'Aligned';
        elseif isAligned == 0 && isCropped == 0 && isEnhanced == 0
            imgCondition = 'Raw';
        else
            fprintf('The image stack does not fulfill preset requirements. Please align the image stack first. \n');
            imgCondition = 'Raw';
        end
        
    end

    function [imstack,nextStatus] = loadImg(imgCondition)
        disp('start loading image')
        % Load the data
        [filename, pathname] = uigetfile('*.tif*', 'Select the data file');
        if isequal(filename,0)
            fprintf('No file selected. Please try again. \n');
            nextStatus = 'loadImg';
        end
        imstack = tiffreadVolume(fullfile(pathname, filename));
        switch imgCondition
            case 'Raw'
                fprintf('The image stack is raw. Please align the image stack first. \n');
                nextStatus = 'correctDrift';
            case 'Aligned'
                fprintf('The image stack is aligned. Please crop the image stack first. \n');
                nextStatus = 'cropImage';
            case 'Aligned&cropped'
                fprintf('The image stack is aligned and cropped. Please enhance the contrast first. \n');
                nextStatus = 'enhanceContrast';
            case 'Enhanced'
                fprintf('The image stack is enhanced. Please detect points first. \n');
                nextStatus = 'pointDetection';
        end
    end

    function [nextStatus] = checkIdleCommand()
        fprintf(['start (s): start from the begining \n quit (q): quit the workflow \n' ...
            'continue (c): continue from where you left due to invalid commands \n']);
         % check menu commands
            userInput = input('Waiting for user command: ', 's');
            if strcmpi(userInput, 'start') || strcmpi(userInput,'s')
                %% ask user about image conditions: aligned, aligned&cropped, enhanced(filtered), or raw
    
                [imgCondition,lastDefaultImgCondition] = askInputImageCondition(lastDefaultImgCondition);
                nextStatus = 'loadImg';
            elseif strcmpi(userInput, 'quit') || strcmpi(userInput,'q')
                nextStatus = 'exit';
            elseif strcmpi(userInput, 'continue') || strcmpi(userInput,'c')
                if strcmpi(previous_status, 'loadImg')
                    disp('Last exit from image laoding section, continue with drift correction...');
                    nextStatus = 'correctDrift';
                elseif strcmpi(previous_status, 'correctDrift')
                    disp('Last exit from drift correction section, continue with ROI cropping...');
                    nextStatus = 'cropImage';
                elseif strcmpi(previous_status,'cropImage')
                    disp('Last exit from ROI cropping section, continue with contrast enhancement...');
                    nextStatus = 'enhanceContrast';
                elseif strcmpi(previous_status, 'enhanceContrast')
                    disp('Last exit from contrast enhancement section, continue with point detection...');
                    nextStatus = 'pointDetection';
                elseif strcmpi(previous_status, 'pointDetection')
                    disp('Last exit from point detection section, continue with point tracking...');
                    nextStatus = 'pointTracking';
                elseif strcmpi(previous_status, 'pointTracking')
                    disp('Last exit from point tracking section, continue with traction calcualtion...');
                    nextStatus = 'tractionCalculation';
                else
                    fprintf('Invalid command. Please try again. \n');
                    nextStatus = 'idle';
                end
            else
                fprintf('Invalid command. Please try again. \n');
                nextStatus = 'idle';
            end
    end

    
    function [imstack_aligned,roi,newDefault,hview] = driftCorrection(defaultReferenceForDriftCorrection)
        disp('start drift correction')
        if length(size(imstack)) > 3
            fprintf("The image stack has more than 3 dimensions. Please select a 3D image stack. \n");
            imstack_aligned = [];
            newDefault = [];
            roi = [];
            return;
        end
        
        % Ask for user inputs
        prompt = {'Enter the reference number:'};
        dlgtitle = 'Which frame is the reference for drift correction';
        dims = [1 100];
        if isempty(defaultReferenceForDriftCorrection) || ...
                defaultReferenceForDriftCorrection == 0 || nargin == 0
            default = {'1'};
        else
            default = {num2str(defaultReferenceForDriftCorrection)};
        end
        userInputs = inputdlg(prompt, dlgtitle, dims, default);

        % Process the user inputs
        refNumber = str2double(userInputs{1});
        
        for iframe = 1:nframes
            imstacktmp(:,:,iframe) = imadjust(mat2gray(imstack(:,:,iframe)));
        end


        % enable drawing in a preview window
        hpreview = figure;
        title('Select an ROI, press ENTER to confirm, DELETE to reselect')
        sliceViewer(imstacktmp);
        % press return to confirm selection; press backspace to redo the
        % selection
        [roi,~,~] = waitROISelection('rectangle','return','backspace',hpreview,[1,1,ncols-1,nrows-1]); 
        close(hpreview);

        drift = computeDrift(imstacktmp, refNumber, roi);
        disp('drift calculation finished...')
        imstack_aligned = translateImgStack(imstacktmp, drift);
        disp('correction completed')
        

        hview = figure;
        title('Preview of drift correction result');
        sliceViewer(imstack_aligned);

        newDefault = refNumber;
    end

    function [imstack_aligned_cropped,roi,hview] = cropAlignedImstack()
        
        % preview previously aligned image stack to select cropping roi
        hpreview = figure;
        title('Select an ROI, press ENTER to confirm, DELETE to reselect')
        sliceViewer(imstack);
        [roi,useFOV,~] = waitROISelection('rectangle','return','backspace',hpreview,[1,1,ncols-1,nrows-1]); 
        close(hpreview);
        % if no rectangular roi is selected, no need to crop.
        if useFOV == 1
            imstack_aligned_cropped = imstack;
        else
            disp('Start cropping...')
            for iframe = 1:nframes
                tmp = imcrop(squeeze(imstack(:,:,iframe)), [roi(1) roi(2) roi(3) roi(4)]);
                imstack_aligned_cropped(:,:,iframe) = tmp;
            end
        end

        disp('image crop finished.')
        % preview of cropped image stack
        hview = figure;
        title('Preview of image cropping result')
        sliceViewer(imstack_aligned_cropped);
        
    end

    function [imstack_filtered,newDefault,sigma1,sigma2,hview] = applyDifferenceOfGaussianFilter(defaultDoF)
         % Ask for user inputs for difference of Gaussian filter
            prompt = {'Enter the standard deviation of the smaller Gaussian filter:', 'Enter the standard deviation of the larger Gaussian filter:'};
            dlgtitle = 'User Inputs for Difference of Gaussian Filter';
            dims = [1 100];
            if nargin == 0 || isempty(defaultDoF)
                default = {'1', '2'};
            else
                default = defaultDoF;
            end
            userInputs = inputdlg(prompt, dlgtitle, dims, default);
            % Process the user inputs
            sigma1 = str2double(userInputs{1});
            sigma2 = str2double(userInputs{2});
            % Apply difference of Gaussian filter
            disp('Start filtering...')
            for iframe = 1:nframes
                tmp = imstack(:,:,iframe);
                if(sigma1 > 0 && sigma2 > 0)
                    imstack_filtered(:,:,iframe) = imgaussfilt(tmp, sigma1) - imgaussfilt(tmp, sigma2);
                end
            end
            disp('Filtering finished.')
            hview = figure;
            title('Preview of filtering result')
            sliceViewer(imstack_filtered);
            
            newDefault = userInputs;
            
    end
    
    function [points,newDefault,minQuality,filterSize,hview] = detectPointsAtRerenceFrame(defaultPointDetection)
        % Ask for user inputs for detection "detectMinEigenFeatures"
            prompt = {'Enter the reference number:', 'Minimum quality threshold:',...
                'Filter size'};
            dlgtitle = 'User Inputs for Point Detection, for parameter details refer to detectMinEigenFeatures documentation';
            dims = [1 100];
            if nargin == 0 || isempty(defaultPointDetection)
                default = {'1', '0.01', '5'};
            else
                default = defaultPointDetection;
            end
            userInputs = inputdlg(prompt, dlgtitle, dims, default);
            newDefault = userInputs;
            % Process the user inputs
            refNumber = str2double(userInputs{1});
            minQuality = str2double(userInputs{2});
            filterSize = str2double(userInputs{3});
            % Detect points
            points = detectMinEigenFeatures(imstack(:,:,refNumber), 'MinQuality', minQuality, 'FilterSize', filterSize);

            % Display the detected points
            disp('Point detection Complete.')
            hview = figure; 
            title('Preview of point detection result')
            imagesc(imstack(:,:,refNumber));
            colormap gray;
            hold on;
            scatter(points.Location(:,1), points.Location(:,2), '.r');

    end
 
    function [input_data,newDefault,blksz,maxBidirectionalError, ...
            numPyramidLevels,hview] = pointTracking(pointTrackingDefault)
                    % Ask for user inputs for tracking
            prompt = {'Reference frame number:', 'Interrogation window size (pix):',...
                'Maximum bidirectional error (pix):', 'Number of pyramid levels:'};
            dlgtitle = 'User Inputs for Point Tracking';
            dims = [1 100];
            if nargin == 0 || isempty(pointTrackingDefault)
                default = {lastDefaultPointDetection{1}, '31', '1', '3'};
            else
                default = pointTrackingDefault;
            end
            userInputs = inputdlg(prompt, dlgtitle, dims, default);
            newDefault = userInputs;
            refNumber = str2double(userInputs{1});
            blksz = str2double(strsplit(userInputs{2}, {' ', ',', ';'}));
            blksz = blksz(:)';
            if isscalar(blksz)
                blksz = [blksz blksz];
            elseif(numel(blksz) > 2)
                blksz = blksz(1:2);
                fprintf("Warning: input window size has more than 2 elements. Only the first 2 elements are used. \n")
            end

            if(mod(blksz(1),2) == 0)
                fprintf("Warning: input window size is not odd. The window size is adjusted to the nearest odd number. \n")
                blksz(1) = blksz(1) + 1;
            end
            if(mod(blksz(2),2) == 0)
                fprintf("Warning: input window size is not odd. The window size is adjusted to the nearest odd number. \n")
                blksz(2) = blksz(2) + 1;
            end
            maxBidirectionalError = str2double(userInputs{3});
            numPyramidLevels = str2double(userInputs{4});
            % Track points
            tracker = vision.PointTracker('MaxBidirectionalError', maxBidirectionalError, 'BlockSize', blksz, 'NumPyramidLevels', numPyramidLevels);
            initialize(tracker, points.Location, imstack(:,:,refNumber));

            for i = 1:nframes
                [points2, valid] = tracker(imstack(:,:,i));
                d = double([points.Location(valid,:), points2(valid,:)-points.Location(valid,:)]);
                input_data.displacement(i).pos = d(:,1:2);
                input_data.displacement(i).vec = d(:,3:4);
            end




            release(tracker);
            disp('tracking displacement completed')
            % Display the tracked points

            ask_scale = inputdlg('Enter a scale factor to visualize tracking results', ...
                'Scale for preview displacement fields',[1 50],{'1'});
            scale_disp = str2double(ask_scale{1});

            hview = figure;
            title('Preview of tracking result')
            if nframes > 2
                if refNumber == 1
                    visual_range = 2:nframes;
                elseif refNumber == nframes
                    visual_range = 1:nframes-1;
                else
                    visual_range = [1:refNumber3-1,refNumber3+1:nframes];
                end

            elseif nframes == 2
                if refNumber == 1
                    visual_range = 2;
                elseif refNumber == 2
                    visual_range =1;
                else
                    error("Erro in reference frame selcetion, should be in the range of the number of frames");
                end
            else
                error("Frame number is less than 1, error in LINE 388 of TFM_main script");
            end
            input_data.displacement(refNumber) = [];


            plotVectorsOnStacks(imstack(:,:,visual_range),input_data.displacement,hview,scale_disp);
    end

end

