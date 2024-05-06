function plotVectorsOnStacks(imstack,vectors,hfig,scale)
% plot vector fields on image stack
% requirement:
% vectors(nframes).pos, vectors(nframe).vec
% imstack(nrows,ncols,nframes);
if size(imstack,3) ~= length(vectors)
    error("Input image stack has a different slices from the input vector field");
end

if nargin == 3
    scale = 1.0;
end

if size(imstack,3) > 1

    sv = sliceViewer(imstack,'Parent',hfig);
    zoom on;
    addlistener(sv,'SliderValueChanging',@allevents);
    addlistener(sv,'SliderValueChanged',@allevents);
elseif size(imstack,3) == 1
    
    imagesc(imstack,'Parent',gca(hfig));colormap gray;
    hold on;
    quiver(vectors.pos(:,1),vectors.pos(:,2),vectors.vec(:,1),vectors.vec(:,2),scale,'r');
end


    function allevents(src,evt)
        evname = evt.EventName;
        if strcmpi(evname,'SliderValueChanging')
            ax = getAxesHandle(src);
            qhandle = findobj(ax,'Type','quiver');
            delete(qhandle);
        elseif strcmpi(evname,'SliderValueChanged')
            ii = evt.CurrentValue;
            hold on;
            quiver(vectors(ii).pos(:,1),vectors(ii).pos(:,2),vectors(ii).vec(:,1),vectors(ii).vec(:,2),scale,'r');
            hold off
        end
    end

end