function TFM_main_clean()

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

%% initialize some variables
status = 'idle';
previous_status = 'none';

process_status = {'loadImg','correctDrift','cropImage','enhanceContrast','pointDetection',...
    'pointTracking','tractionCalculation'};


nrows = 0; ncols = 0; nframes = 0;

%% ask user about image conditions: aligned, aligned&cropped, enhanced(filtered), or raw

imgCondition = askInputImageCondition();

%% main processing loop, capable for processing multiple files manually, no need to exit the script.
% However, batch processing is not supported yet.

while true

    % record last process status in case that the user types wrong commands
    % allow the user to go back to the previous step
    if(ismember(status,process_status))
        previous_status = status;
    end

    switch status
        case 'idle'
            status = askIdle();
        case 'exit'
            disp('Exit the TFM full workflow...')
            break;
        case 'loadImg'
            disp('start loading image')
            % Load the data
            [filename, pathname] = uigetfile('*.tif*', 'Select the data file');
            if isequal(filename,0)
                fprintf('No file selected. Please try again. \n');
                status = 'loadImg';
                continue;
            end
            imstack_raw = tiffreadVolume(fullfile(pathname, filename));

            status = 'correctDrift';

        case 'correctDrift'
            [status,roi] = driftCorrection();

        case 'cropImage'
        case 'enhanceContrast'
        case 'pointDetection'
        case 'pointTracking'
        case 'tractionCalculation'
        case 'saveData'
    end

end




    function imgCondition = askInputImageCondition()
        
        prompt = {'Is the image stack algined?', 'Is the image stack aligned and cropped?',...
            'Is the image stack enhanced?'};
        dlgtitle = 'Does the image stack fulfill the requirements? (1 for yes, 0 for no)';
        dims = [1 100];
        default = {'1', '1','1','1'};
        userInput = inputdlg(prompt, dlgtitle,dims,default);
        isAligned = str2double(userInput{1});
        isCropped = str2double(userInput{2});
        isEnhanced = str2double(userInput{3});
        
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

    function nextStatus = askIdle()
        fprintf(['start (s): start from the begining \n quit (q): quit the workflow \n' ...
            'continue (c): continue from where you left due to invalid commands \n']);
        userInput = input('Waiting for user command: ', 's');
        if strcmpi(userInput, 'start') || strcmpi(userInput,'s')
            switch imgCondition
                case 'Raw'
                    fprintf('The image stack is raw. Please align the image stack first. \n');
                    nextStatus = 'loadImg';
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

    
    function [nextStatus,roi] = driftCorrection()
        disp('start drift correction')
        if length(size(imstack_raw)) > 3
            fprintf("The image stack has more than 3 dimensions. Please select a 3D image stack. \n");
            nextStatus = 'loadImg';
            roi = [];
            return;
        end
        nrows = size(imstack_raw,1);
        ncols = size(imstack_raw,2);
        nframes = size(imstack_raw,3);
        % normalize the brightness
        for i = 1:nframes
            imstack(:,:,i) = imadjust(mat2gray(imstack_raw(:,:,i)));
        end

        % Ask for user inputs
        prompt = {'Enter the reference number:', 'Enter the ROI (x,y,w,h):'};
        dlgtitle = 'User Inputs for Drift Correction';
        dims = [1 100];
        defroi = strcat(num2str(1),',',num2str(1),',',num2str(ncols),',',num2str(nrows));
        default = {'1', defroi};
        userInputs1 = inputdlg(prompt, dlgtitle, dims, default);

        % Process the user inputs
        refNumber1 = str2double(userInputs1{1});
        roi = str2double(strsplit(userInputs1{2}, {' ', ',', ';'}));
        roi = roi(:)';

        drift = computeDrift(imstack, refNumber1, roi1);
        disp('drift calculation finished...')
        imstack_aligned = translateImgStack(imstack, drift);
        disp('correction completed')
        hview = figure;
        sliceViewer(imstack_aligned);
        
        userDecision = input('Type continue to proceed, redo to redo drift correction: ','s');
        if strcmpi(userDecision,'continue') || strcmpi(userDecision,'c')
            nextStatus = 'cropImage';
        elseif strcmpi(userDecision,'redo')|| strcmpi(userDecision,'r')
            nextStatus = 'correctDrift';
        else
            nextStatus = 'idle';
        end
        if isvalid(hview)
            close(hview);
        end
    end

end