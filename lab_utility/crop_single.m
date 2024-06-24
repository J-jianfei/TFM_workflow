function varargin = crop_single(varargin)
% crop and save single image stacks
[filename, pathname] = uigetfile({'*.tif';'*.tiff'}, 'Select a tif file');
fullname = fullfile([pathname,filename]);
if(filename == 0)
    disp('No file selected');
    return;
end
disp('Loading Images, Please Wait...');

info = imfinfo(fullname);
description = info(1).ImageDescription;

nchannels = findNumAfterStr(description,'channels=');
nframes = findNumAfterStr(description,'frames=');
width = info(1).Width;
height = info(1).Height;
% if channel index is not correct, change here
cell_channel = 1;
bead_channel = 2;



imcell = tiffreadVolume(fullname,"PixelRegion",{[1,height],[1,width],[cell_channel,nchannels,nframes*nchannels]});
imbead = tiffreadVolume(fullname,'PixelRegion',{[1,height],[1,width],[bead_channel,nchannels,nframes*nchannels]});

channels = 1:nchannels;
remain_channels = channels(channels ~= bead_channel);

for i = 1:length(remain_channels)
    imch{i} = tiffreadVolume(fullname, "PixelRegion",{[1,height],[1,width],[remain_channels(i),nchannels,nframes*nchannels]});
end





h = figure;
disp("Select ROI, press enter to confirm selection");
sv = sliceViewer(imcell,'Parent',h);

count = 1;
while true
    [roi,~,err,roiObj] = waitROISelection('rect','return','backspace',h);

    if(~isempty(roi) && err == 0)
        framesToCrop = askCroppingFrames();
        imbead_cropped = crop_stack(imbead,roi,framesToCrop);
        
        h2 = figure;
        sv2 = sliceViewer(imbead_cropped,"Parent",h2);
        isconfirmed = checkKeyInFig(h2,'return','backspace');
        if(isvalid(h2))
            close(h2)
        end
        if(~isconfirmed)
            continue;
        end


        fullname_noext = fullname(1:strfind(fullname,'.tif')-1);
        if(~exist(fullname_noext,'dir'))
            mkdir(fullname_noext);
        end
        savefolder = fullfile([fullname_noext,'/Cell_',num2str(count)]);
        if(~exist(savefolder,'dir'))
            mkdir(savefolder);
        end

        writeTiffStack(imbead_cropped, fullfile([savefolder,'/Stack_',num2str(count),'_bead','.tif']));

        for i = 1:length(imch)
            imch_cropped = crop_stack(imch{i},roi,framesToCrop);
            writeTiffStack(imch_cropped,fullfile([savefolder,'/Stack_',num2str(count),'_ch',num2str(remain_channels(i)),'.tif']));
        end

        save(fullfile([savefolder,'/ROI_',num2str(count),'.mat']),'roi','framesToCrop');
        count = count + 1;
        answer = questdlg('A new ROI selection in the same file?','Proceed or not','Yes','No','Yes');
        switch answer
            case 'Yes'
                delete(roiObj);
                if ~isvalid(h)
                    h = figure;
                    sv = sliceViewer(imcell,'Parent',h);
                end
            case 'No'
                if isvalid(h)
                    close(h)
                end
                break;
        end

    end

end

end

function num = findNumAfterStr(str,strToFind)
index = strfind(str, strToFind);
if ~isempty(index)
    startIndex = index + length(strToFind);
    endIndex = startIndex;
    for i = startIndex+1 : length(str)
        if(isnan(str2double(str(i))))
            break
        else
            endIndex = i;
        end
    end
    num = str2double(str(startIndex:endIndex));
else
    num = nan;
end

end

function framesToCrop = askCroppingFrames()
d = dialog('Position',[300 300 250 200],'Name','Ref and Def frame numbers');

ref_frame = nan;
def_frame = nan;
% Add text boxes and edit fields
txt1 = uicontrol('Parent',d,...
    'Style','text',...
    'Position',[20 130 210 40],...
    'String','Enter the reference frame');
edit1 = uicontrol('Parent',d,...
    'Style','edit',...
    'Position',[75 120 100 25]);

txt2 = uicontrol('Parent',d,...
    'Style','text',...
    'Position',[20 80 210 40],...
    'String','Enter the deformed frame');
edit2 = uicontrol('Parent',d,...
    'Style','edit',...
    'Position',[75 70 100 25]);

% Add a button
btn = uicontrol('Parent',d,...
    'Position',[85 20 70 25],...
    'String','Confirm',...
    'Callback',@buttonCallback);



    function buttonCallback(src,event)
        ref_frame = str2double(get(edit1,'String'));
        def_frame = str2double(get(edit2,'String'));
        framesToCrop = [ref_frame,def_frame];
        delete(d);
    end

uiwait(d);


end

function writeTiffStack(im, filename)
for i = 1:size(im,3)
    if i == 1
        imwrite(im(:,:,i),filename,'WriteMode','overwrite','Compression','none');
    else
        imwrite(im(:,:,i),filename,'WriteMode','append','Compression','none');
    end
end
end

function imstack_cropped = crop_stack(imstack,rect,frames)
nframes = length(frames);
for i = 1:nframes
    imstack_cropped(:,:,i) = imcrop(imstack(:,:,frames(i)),rect);
end
end

function confirmed = checkKeyInFig(fig,keyyes,keyno)
while true 
    if (waitforbuttonpress)
        key = get(fig,'CurrentKey');
        if strcmpi(key,keyyes)
            confirmed = 1;
            break;
        elseif strcmpi(key,keyno)
            confirmed = 0;
            break;
        end
    end
end
delete(fig);

end