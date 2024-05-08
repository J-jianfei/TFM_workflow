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

lastDefaultImgCondition = {};
lastDefaultReferenceForDriftCorrection = 1;
settings = struct;
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
            [imstack_aligned,status,roi_driftcorrection,...
                lastDefaultReferenceForDriftCorrection] = driftCorrection(lastDefaultReferenceForDriftCorrection);
            settings.driftCorrectionROI = roi_driftcorrection;
        case 'cropImage' 
            % crop images to exclude potental black boarders due to alignment
            % if the drift is too large
            % check existance of aligned images, if not, meaning that the 
            % user wants to import aligned images from the folder by
            % previous imgCondition check.
            if ~exist('imstack_aligned','var')
                [filename, pathname] = uigetfile('*.tif*', 'Select the data file');
                if isequal(filename,0)
                    fprintf('No file selected. Please try again. \n');
                    status = 'loadImg';
                    continue;
                end
                imstack = tiffreadVolume(fullfile(pathname, filename));
                nframes = size(imstack,3);
                ncols = size(imstack,2);
                nrows = size(imstack,1);
                for i = 1:size(imstack,3)
                    imstack_aligned(:,:,i) = imadjust(mat2gray(imstack(:,:,i)));
                end
                clearvar imstack;
            end
            

            [imstack_aligned_cropped,status,roi_crop] = cropAlignedImstack();


            settings.cropROI = roi_crop;


        case 'enhanceContrast'
            % check existance of previously processed data
            if ~exist("imstack_aligned_cropped","var")
                [filename, pathname] = uigetfile('*.tif*', 'Select the data file');
                if isequal(filename,0)
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
                clearvars imstack;
            end


        case 'pointDetection'
        case 'pointTracking'
        case 'tractionCalculation'
        case 'saveData'
    end

end




    function [imgCondition,newDefault] = askInputImageCondition(defaultImgCondition)
        
        prompt = {'Is the image stack algined?', 'Is the image stack aligned and cropped?',...
            'Is the image stack enhanced?'};
        dlgtitle = 'Does the image stack fulfill the requirements? (1 for yes, 0 for no)';
        dims = [1 100];
        if nargin == 0 || isempty(defaultImgCondition)
            default = {'1', '1','1','1'};
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

    function nextStatus = askIdle()
        fprintf(['start (s): start from the begining \n quit (q): quit the workflow \n' ...
            'continue (c): continue from where you left due to invalid commands \n']);
        userInput = input('Waiting for user command: ', 's');
        if strcmpi(userInput, 'start') || strcmpi(userInput,'s')
                %% ask user about image conditions: aligned, aligned&cropped, enhanced(filtered), or raw

            [imgCondition,lastDefaultImgCondition] = askInputImageCondition(lastDefaultImgCondition);
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

    
    function [imstack_aligned,nextStatus,roi,newDefault] = driftCorrection(defaultReferenceForDriftCorrection)
        disp('start drift correction')
        if length(size(imstack_raw)) > 3
            fprintf("The image stack has more than 3 dimensions. Please select a 3D image stack. \n");
            nextStatus = 'loadImg';
            imstack_aligned = [];
            newDefault = [];
            roi = [];
            return;
        end
        nrows = size(imstack_raw,1);
        ncols = size(imstack_raw,2);
        nframes = size(imstack_raw,3);
        % normalize the brightness
        for iframe = 1:nframes
            imstacktmp(:,:,iframe) = imadjust(mat2gray(imstack_raw(:,:,iframe)));
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
        
        


        % enable drawing in a preview window
        hpreview = figure; sliceViewer(imstacktmp);
        % press return to confirm selection; press backspace to redo the
        % selection
        [roi,~,~] = waitROISelection('rectangle','return','backspace',hpreview,[1,1,ncols-1,nrows-1]); 


        drift = computeDrift(imstacktmp, refNumber, roi);
        disp('drift calculation finished...')
        imstack_aligned = translateImgStack(imstacktmp, drift);
        disp('correction completed')
        close(hpreview);

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

        newDefault = refNumber;
    end

    function [imstack_aligned_cropped,nextStatus,roi] = cropAlignedImstack()
        
        % preview previously aligned image stack to select cropping roi
        hpreview = figure;
        sliceViewer(imstack_aligned);
        [roi,useFOV,~] = waitROISelection('rectangle','return','backspace',hpreview,[1,1,ncols-1,nrows-1]); 
        
        % if no rectangular roi is selected, no need to crop.
        if useFOV == 1
            imstack_aligned_cropped = imstack_aligned;
        else
            for iframe = 1:nframes
                imstack_aligned_cropped(:,:,iframe) = imcrop(imstack_aligned(:,:,iframe), [roi2(1) roi2(2) roi2(4) roi2(3)]);
            end
        end

        
        % preview of cropped image stack
        hview = figure;
        sliceViewer(imstack_aligned_cropped);

        userDecision = input('Type continue to proceed, redo to redo cropping: ', 's');
        if strcmpi(userDecision, 'continue') || strcmpi(userDecision,'c')
            nextStatus = 'enhanceContrast';
        elseif strcmpi(userDecision, 'redo') || strcmpi(userDecision,'r')
            nextStatus = 'cropImage';
        else
            fprintf('Invalid input. Please try again. \n');
            nextStatus = 'idle';
        end
        if isvalid(hview)
            close(hview);
        end
        
    end

    



end

function [roi,useFOV,errorcode] = waitROISelection(roiType,keyconfirm,keyrechoose,fig,varargin)
   
    
    if ~strcmpi(roiType,'rectangle') && ~strcmpi(roiType,'rect') && ...
            ~strcmpi(roiType,'polygon') && ~strcmpi(roiType,'poly')
        fprintf("Unrecognized ROI type, first input argument error. \n")
        errorcode = 1;
        roi = [];
        useFOV = 0;
        return;
    end
    
     % first by default the entire region is roi
    if length(varargin) == 1  
        default = varargin{1};
        roiObj = drawrectangle('Position',default);
    end

   


while true
    if strcmpi(roiType,'rectangle') || strcmpi(roiType,'rect')
        
        isconfirm = checkConfirm();
        if(isconfirm == 1)
            roi = roiObj.Position;
            errorcode = 0;
            break;
        else
            delete(roiObj); % re-selection
            roiObj = drawrectangle;
        end
    elseif strcmpi(roiType,'polygon') || strcmpi(roiType,'poly')
        isconfirm = checkConfirm();
        if(isconfirm == 1)
            roi = roiObj.Position;
            errorcode = 0;
            break;
        else
            delete(roiObj); % re-selection
            roiObj = drawpolygon;
        end
    end
end

if ~exist("default","var")
    useFOV = 0;
else
    if isequal(roi,default)
        useFOV = 1;
    end
end

    function confirmed = checkConfirm()
        while true
            waitforbuttonpress;
            key = get(fig,'CurrentKey');
            if strcmpi(key,keyconfirm)
                confirmed = 1;
                break;
            elseif strcmpi(key,keyrechoose)
                confirmed = 0;
                break
            end
        end
    end


end