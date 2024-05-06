%% script of TFM quick analysis
clear
clc

workingDir = uigetdir('Select a working directory');
if workingDir == 0
    error('No directory selected. Exiting...');
end
cd(workingDir);

status = 'idle';
previous_status = 'none';

process_status = {'loadImg','correctDrift','cropImage','enhanceContrast','pointDetection',...
    'pointTracking','tractionCalculation'};

fprintf('Welcome to TFM quick analysis.Here are some commands used to process images. \n');

%%
processing = true;

% Ask the user if the image stack fulfills the requirements
            prompt0 = {'Is the image stack algined?', 'Is the image stack aligned and cropped?',...
                'Is the image stack enhanced?'};
            dlgtitle0 = 'Does the image stack fulfill the requirements? (1 for yes, 0 for no)';
            dims0 = [1 50];
            default0 = {'1', '1','1','1'};
            userInput0 = inputdlg(prompt0, dlgtitle0, dims0,default0);
isAligned = str2double(userInput0{1});
isCropped = str2double(userInput0{2});
isEnhanced = str2double(userInput0{3});

if isAligned == 1 && isCropped == 1 && isEnhanced == 1
    fulfillsRequirements = 'Enhanced';
elseif isAligned == 1 && isCropped == 1 && isEnhanced == 0
    fulfillsRequirements = 'Aligned&cropped';
elseif isAligned == 1 && isCropped == 0 && isEnhanced == 0
    fulfillsRequirements = 'Aligned';
elseif isAligned == 0 && isCropped == 0 && isEnhanced == 0
    fulfillsRequirements = 'Raw';
else
    fprintf('The image stack does not fulfill preset requirements. Please align the image stack first. \n');
    fulfillsRequirements = 'Raw';
end






while processing

    if(ismember(status,process_status))
        previous_status = status;
    end

    switch status
        case 'idle'
            fprintf(['start (s): start from the begining \n quit (q): quit the workflow \n' ...
                'continue (c): continue from where you left due to invalid commands \n']);
            userInput = input('Waiting for user command: ', 's');
            if strcmpi(userInput, 'start') || strcmpi(userInput,'s')
                switch fulfillsRequirements
                    case 'Raw'
                        fprintf('The image stack is raw. Please align the image stack first. \n');
                        status = 'loadImg';
                    case 'Aligned'
                        fprintf('The image stack is aligned. Please crop the image stack first. \n');
                        status = 'cropImage';
                    case 'Aligned&cropped'
                        fprintf('The image stack is aligned and cropped. Please enhance the contrast first. \n');
                        status = 'enhanceContrast';
                    case 'Enhanced'
                        fprintf('The image stack is enhanced. Please detect points first. \n');
                        status = 'pointDetection';
                end
            elseif strcmpi(userInput, 'quit') || strcmpi(userInput,'q')
                status = 'exit';
            elseif strcmpi(userInput, 'continue') || strcmpi(userInput,'c')
                if strcmpi(previous_status, 'loadImg')
                    disp('Last exit from image laoding section, continue with drift correction...');
                    status = 'correctDrift';
                elseif strcmpi(previous_status, 'correctDrift')
                    disp('Last exit from drift correction section, continue with ROI cropping...');
                    status = 'cropImage';
                elseif strcmpi(previous_status,'cropImage')
                    disp('Last exit from ROI cropping section, continue with contrast enhancement...');
                    status = 'enhanceContrast';
                elseif strcmpi(previous_status, 'enhanceContrast')
                    disp('Last exit from contrast enhancement section, continue with point detection...');
                    status = 'pointDetection';
                elseif strcmpi(previous_status, 'pointDetection')
                    disp('Last exit from point detection section, continue with point tracking...');
                    status = 'pointTracking';
                elseif strcmpi(previous_status, 'pointTracking')
                    disp('Last exit from point tracking section, continue with traction calcualtion...');
                    status = 'tractionCalculation';
                else
                    fprintf('Invalid command. Please try again. \n');
                    status = 'idle';
                end
            else
                fprintf('Invalid command. Please try again. \n');
                status = 'idle';
            end
        case 'exit'
            disp('Exit the TFM full workflow...')
            processing = false;
            break;
        case 'loadImg'
            disp('start loading image')
            % Load the data
            [filename, pathname] = uigetfile('*.tif*', 'Select the data file');
            if filename == 0
                fprintf('No file selected. Please try again. \n');
                status = 'loadImg';
                break;
            end
            imstack_raw = tiffreadVolume(fullfile(pathname, filename));

            status = 'correctDrift';
        case 'correctDrift'
            disp('start drift correction')
            if length(size(imstack_raw)) > 3
                fprintf("The image stack has more than 3 dimensions. Please select a 3D image stack. \n");
                status = 'loadImg';
                break;
            end
            nrows = size(imstack_raw,1);
            ncols = size(imstack_raw,2);
            nframes = size(imstack_raw,3);
            % normalize the brightness
            for i = 1:nframes
                imstack(:,:,i) = imadjust(mat2gray(imstack_raw(:,:,i)));
            end

            % Ask for user inputs
            prompt1 = {'Enter the reference number:', 'Enter the ROI (x,y,w,h):'};
            dlgtitle1 = 'User Inputs for Drift Correction';
            dims1 = [1 50];
            defroi1 = strcat(num2str(1),',',num2str(1),',',num2str(ncols),',',num2str(nrows));
            default1 = {'1', defroi1};
            userInputs1 = inputdlg(prompt1, dlgtitle1, dims1,default1);

            % Process the user inputs
            refNumber1 = str2double(userInputs1{1});
            roi1 = str2double(strsplit(userInputs1{2}, {' ', ',', ';'}));
            roi1 = roi1(:)';

            drift = computeDrift(imstack, refNumber1, roi1);
            disp('drift calculation finished...')
            imstack_aligned = translateImgStack(imstack, drift);
            disp('correction completed')
            hview1 = figure;
            sliceViewer(imstack_aligned);
            
            userDecision = input('Type continue to proceed, redo to redo drift correction: ','s');
            if strcmpi(userDecision,'continue') || strcmpi(userDecision,'c')
                status = 'cropImage';
            elseif strcmpi(userDecision,'redo')|| strcmpi(userDecision,'r')
                status = 'correctDrift';
            else
                status = 'idle';
            end
            if isvalid(hview1)
                close(hview1);
            end

            settings.driftCorrectionROI = roi1;

        case 'cropImage'

            if ~exist('imstack_aligned','var')
                [filename, pathname] = uigetfile('*.tif*', 'Select the data file');
                if filename == 0
                    fprintf('No file selected. Please try again. \n');
                    status = 'loadImg';
                    break;
                end
                imstack = tiffreadVolume(fullfile(pathname, filename));
                nframes = size(imstack,3);
                ncols = size(imstack,2);
                nrows = size(imstack,1);
                for i = 1:size(imstack,3)
                    imstack_aligned(:,:,i) = imadjust(mat2gray(imstack(:,:,i)));
                end
            end

            prompt2={'Enter ROI to crop the image (x,y,w,h):'};
            dlgtitle2 = 'User Inputs for Cropping';
            dims2 = [1 50];
            defroi2 = strcat(num2str(1),',',num2str(1),',',num2str(ncols),',',num2str(nrows));
            userInputs2 = inputdlg(prompt2, dlgtitle2, dims2, {defroi2});

            roi2 = str2double(strsplit(userInputs2{1}, {' ', ',', ';'}));
            roi2 = roi2(:)';

        

            for i = 1:nframes
                imstack_aligned_cropped(:,:,i) = imcrop(imstack_aligned(:,:,i), roi2);
            end


            hview2 = figure;
            sliceViewer(imstack_aligned_cropped);
            
            userDecision = input('Type continue to proceed, redo to redo cropping: ', 's');
            if strcmpi(userDecision, 'continue') || strcmpi(userDecision,'c')
                status = 'enhanceContrast';
            elseif strcmpi(userDecision, 'redo') || strcmpi(userDecision,'r')
                status = 'cropImage';
            else
                fprintf('Invalid input. Please try again. \n');
                status = 'idle';
            end
            if isvalid(hview2)
                close(hview2);
            end
            settings.cropROI = roi2;
        case 'enhanceContrast'
            % Enhance contrast
            if ~exist("imstack_aligned_cropped","var")
                [filename, pathname] = uigetfile('*.tif*', 'Select the data file');
                if filename == 0
                    fprintf('No file selected. Please try again. \n');
                    status = 'loadImg';
                    break;
                end
                imstack = tiffreadVolume(fullfile(pathname, filename));
                nframes = size(imstack,3);
                ncols = size(imstack,2);
                nrows = size(imstack,1);
                for i = 1:size(imstack,3)
                    imstack_aligned_cropped(:,:,i) = imadjust(mat2gray(imstack(:,:,i)));
                end

            end
            % Ask for user inputs for difference of Gaussian filter
            prompt4 = {'Enter the standard deviation of the smaller Gaussian filter:', 'Enter the standard deviation of the larger Gaussian filter:'};
            dlgtitle4 = 'User Inputs for Difference of Gaussian Filter';
            dims4 = [1 50];
            default4 = {'1', '2'};
            userInputs4 = inputdlg(prompt4, dlgtitle4, dims4, default4);
            % Process the user inputs
            sigma1 = str2double(userInputs4{1});
            sigma2 = str2double(userInputs4{2});
            % Apply difference of Gaussian filter
            for i = 1:nframes
                tmp = imstack_aligned_cropped(:,:,i);
                if(sigma1 > 0 && sigma2 > 0)
                    imstack_filtered(:,:,i) = imgaussfilt(tmp, sigma1) - imgaussfilt(tmp, sigma2);
                end
            end
            hview4 = figure;sliceViewer(imstack_filtered);


            userDecision = input('Type continue to proceed, redo to redo contrast enhancement: ', 's');
            if strcmpi(userDecision, 'continue') || strcmpi(userDecision,'c')
                status = 'pointDetection';
            elseif strcmpi(userDecision, 'redo') || strcmpi(userDecision,'r')
                status = 'enhanceContrast';
            else
                fprintf('Invalid input. Please try again. \n');
                status = 'idle';
            end
            if isvalid(hview4)
                close(hview4);
            end
            
            % settings 
            settings.sigma1 = sigma1;
            settings.sigma2 = sigma2;
        case 'pointDetection'
            
            if ~exist("imstack_filtered","var")
                [filename, pathname] = uigetfile('*.tif*', 'Select the data file');
                if filename == 0
                    fprintf('No file selected. Please try again. \n');
                    status = 'loadImg';
                    break;
                end
                imstack_filtered = tiffreadVolume(fullfile(pathname, filename));
                nframes = size(imstack_filtered,3);
                ncols = size(imstack_filtered,2);
                nrows = size(imstack_filtered,1);
            end
            
            % Ask for user inputs for detection "detectMinEigenFeatures"
            prompt3 = {'Enter the reference number:', 'Minimum quality threshold:',...
                'Filter size'};
            dlgtitle3 = 'User Inputs for Point Detection, for parameter details refer to detectMinEigenFeatures documentation';
            dims3 = [1 50];
            default3 = {'1', '0.01', '5'};
            userInputs3 = inputdlg(prompt3, dlgtitle3, dims3, default3);

            % Process the user inputs
            refNumber2 = str2double(userInputs3{1});
            minQuality = str2double(userInputs3{2});
            filterSize = str2double(userInputs3{3});
            % Detect points
            points = detectMinEigenFeatures(imstack_filtered(:,:,refNumber2), 'MinQuality', minQuality, 'FilterSize', filterSize);

            % Display the detected points

            hview3 = figure; imagesc(imstack_filtered(:,:,refNumber2));
            colormap gray;
            hold on;
            scatter(points.Location(:,1), points.Location(:,2), '.r');

            userDecision = input('Type continue to proceed, redo to redo point detection: ', 's');
            if strcmpi(userDecision, 'continue') || strcmpi(userDecision,'c')
                status = 'pointTracking';
            elseif strcmpi(userDecision, 'redo') || strcmpi(userDecision,'r')
                status = 'pointDetection';
            else
                fprintf('Invalid input. Please try again. \n');
                status = 'idle';
            end

            if isvalid(hview3)
                close(hview3);
            end
            % organizing settings
            settings.minQuality = minQuality;
            settings.filterSize = filterSize;
        case 'pointTracking'
            % Ask for user inputs for tracking
            prompt5 = {'Reference frame number:', 'Interrogation window size (pix):',...
                'Maximum bidirectional error (pix):', 'Number of pyramid levels:'};
            dlgtitle5 = 'User Inputs for Point Tracking';
            dims5 = [1 50];
            default5 = {num2str(refNumber2), '31', '1', '3'};
            userInputs5 = inputdlg(prompt5, dlgtitle5, dims5, default5);
            refNumber3 = str2double(userInputs5{1});
            blksz = str2double(strsplit(userInputs5{2}, {' ', ',', ';'}));
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
            maxBidirectionalError = str2double(userInputs5{3});
            numPyramidLevels = str2double(userInputs5{4});
            % Track points
            tracker = vision.PointTracker('MaxBidirectionalError', maxBidirectionalError, 'BlockSize', blksz, 'NumPyramidLevels', numPyramidLevels);
            initialize(tracker, points.Location, imstack_filtered(:,:,refNumber3));
            
            for i = 1:nframes
                [points2, valid] = tracker(imstack_filtered(:,:,i));
                d = double([points.Location(valid,:), points2(valid,:)-points.Location(valid,:)]);
                input_data.displacement(i).pos = d(:,1:2);
                input_data.displacement(i).vec = d(:,3:4);
            end
            
            


            release(tracker);
            disp('tracking displacement completed')
            % Display the tracked points
            clearvars points point2 valid d
            ask_scale = inputdlg('Enter a scale factor to visualize tracking results', ...
                'Scale for preview displacement fields',[1 50],{'1'});
            scale_disp = str2double(ask_scale{1});
            
            hview5 = figure; 
            if nframes > 2
                if refNumber3 == 1
                    visual_range = 2:nframes;
                elseif refNumber3 == nframes
                    visual_range = 1:nframes-1;
                else
                    visual_range = [1:refNumber3-1,refNumber3+1:nframes];
                end
                
            elseif nframes == 2
                if refNumber3 == 1
                    visual_range = 2;
                elseif refNumber3 == 2
                    visual_range =1;
                else
                    error("Erro in reference frame selcetion, should be in the range of the number of frames");
                end
            else
                error("Frame number is less than 1, error in LINE 388 of TFM_main script");    
            end
            input_data.displacement(refNumber3) = [];
            
            
            plotVectorsOnStacks(imstack_filtered(:,:,visual_range),input_data.displacement,hview5,scale_disp);

            userDecision = input('Type continue to proceed, redo to redo point tracking: ', 's');
            if strcmpi(userDecision, 'continue') || strcmpi(userDecision,'c')
                status = 'tractionCalculation';
            elseif strcmpi(userDecision, 'redo') || strcmpi(userDecision,'r')
                status = 'pointTracking';
            else
                fprintf('Invalid input. Please try again. \n');
                status = 'idle';
            end

            if isvalid(hview5)
                close(hview5);
            end
            % organzing settings to save
            settings.maxBidirectionalError = maxBidirectionalError;
            settings.blockSize = blksz;
            settings.numPyramidLevels = numPyramidLevels;

        case 'tractionCalculation'
            % Ask for user inputs for traction calculation
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
            disp('DONOT CHANGE THE DEFAULT OUTPUT FILENAME!')
            TF_reconstruction;
            
            userDecision = input('Type continue to proceed, redo to redo traction calculations:', 's');
            if strcmpi(userDecision, 'continue') || strcmpi(userDecision,'c') || strcmpi(userDecision,'')
                status = 'saveData';
            elseif strcmpi(userDecision, 'redo') || strcmpi(userDecision,'r')
                status = 'tractionCalculation';
            else
                fprintf('Invalid input. Please try again. \n');
                status = 'idle';
            end
            % Check for files matching the pattern "Bay-FTTC*.mat"
            files_bay = dir('Bay-FTTC*.mat');
            % Check for files matching the pattern "Reg-FTTC*.mat"
            files_reg = dir('Reg-FTTC*.mat');

            % Check if any files were found
            if ~isempty(files_bay) || ~isempty(files_reg)
                % Display the matching files
                for i = 1:length(files_bay)
                    attempt_bay(i) = load(files_bay(i).name);
                end
                
                for i = 1:length(files_reg)
                    attempt_reg(i) = load(files_reg(i).name);
                end
            else
                disp('No matching files found in the current folder, TF_recontruction might exit wrongly.');
            end
            disp('exit the temporary folder');
            cd ../;
            rmdir(tempdir,'s');
        case 'saveData'
            
            savefullname = fullfile(pathname,strcat(filename(1:end-4),'_TFM_output.mat'));
            % Save the data
            [savefilename, savepathname] = uiputfile(savefullname, 'Save the data');
            if savefilename == 0
                fprintf('No file selected. Please Enter filename manually. \n');
                status = 'saveData';
                break;
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
            clearvars im* 
    end


end





