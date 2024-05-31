function [roi,useFOV,errorcode,roiObj] = waitROISelection(roiType,keyconfirm,keyrechoose,fig,varargin)
   
    
    if ~strcmpi(roiType,'rectangle') && ~strcmpi(roiType,'rect') && ...
            ~strcmpi(roiType,'polygon') && ~strcmpi(roiType,'poly')
        fprintf("Unrecognized ROI type, first input argument error. \n")
        errorcode = 1;
        roi = [];
        useFOV = 0;
        return;
    end
    
     % first by default the entire region is roi
    if isscalar(varargin)  
        default = varargin{1};
        roiObj = drawrectangle('Position',default);
    end
    

    if strcmpi(roiType,'polygon') || strcmpi(roiType,'poly')
        roiObj = drawpolygon;
    end

    if strcmpi(roiType,'rectangle') || strcmpi(roiType,'rect')
         roiObj = drawrectangle;
    end


while true
    if strcmpi(roiType,'rectangle') || strcmpi(roiType,'rect')
        
        [isconfirm,redraw] = checkConfirm();
        if(isconfirm == 1)
            roi = roiObj.Position;
            errorcode = 0;
            break;
        elseif (isconfirm == 0) && (redraw == 1)
            delete(roiObj); % re-selection
            roiObj = drawrectangle;
        end
    elseif strcmpi(roiType,'polygon') || strcmpi(roiType,'poly')
        [isconfirm,redraw] = checkConfirm();
        if(isconfirm == 1)
            roi = roiObj.Position;
            errorcode = 0;
            break;
        elseif (isconfirm == 0) && (redraw == 1)
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
    else
        useFOV = 0;
    end
end

    function [confirmed,redraw] = checkConfirm()
        redraw = 0;
        while true
            if (waitforbuttonpress)
                key = get(fig,'CurrentKey');
                if strcmpi(key,keyconfirm)
                    confirmed = 1;
                    break;
                elseif strcmpi(key,keyrechoose)
                    confirmed = 0;
                    redraw = 1;
                    break
                end
            else
                redraw = 0;
            end
        end
    end


end