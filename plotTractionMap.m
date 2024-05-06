function h = plotTractionMap(TFM_results,varargin)
    % Plot the traction map
    % 
    % Usage:
    %   h = plotTractionMap(tractionMap)
    %   h = plotTractionMap(tractionMap, 'Name', Value)
    % 
    % Inputs:
    %   tractionMap: 2D matrix of traction values
    % 
    % Name-Value pairs:
    %   'ColorMap': colormap to use
    %   'ColorBar': show colorbar
    %   'Title': title of the plot
    %  
    % 
    % Outputs:
    %   h: handle to the plot
    % 
    % See also: imagesc, colormap, colorbar, title, axis

    p = inputParser;
    addRequired(p, 'TFM_results', @isstruct);
    addParameter(p, 'PlotType', 'magnitude', @(x) ischar(x) && ismember(x, {'magnitude', 'vector'}));
    addParameter(p, 'ColorMap', 'jet', @ischar);
    addParameter(p, 'ColorBar', true, @islogical);
    addParameter(p, 'Title', '', @ischar);
    addParameter(p, 'XLabel', '', @ischar);
    addParameter(p, 'YLabel', '', @ischar);
    addParameter(p, 'Scale', 1, @isnumeric);
    addParameter(p, 'LineStyle', '-r', @ischar);
    addParameter(p, 'LineWidth', 1, @isnumeric);
    addParameter(p, 'MaxHeadSize', 0.5, @isnumeric);
    addParameter(p, 'FontSize', 12, @isnumeric);

    parse(p, TFM_results, varargin{:});



    nframes = length(TFM_results);
    if nframes > 1
        disp('This TFM_results have multiple frames, please select one frame to plot the traction map');
        i = str2double(input('Select the frame number to plot','s'));
    else
        i = 1;
    end

    x = TFM_results(i).pos(:,1);
    y = TFM_results(i).pos(:,2);

    unique_x = unique(x);
    sorted_x = sort(unique_x, 'descend');
    meshsize = sorted_x(1) - sorted_x(2);





    % Plot the traction map

    if strcmp(p.Results.PlotType, 'magnitude')
            % Convert x and y to mesh grids
            fn = TFM_results(i).traction_magnitude;
    [X, Y] = meshgrid(min(x):meshsize:max(x), min(y):meshsize:max(y));

    % Interpolate traction values onto mesh grid
    Tn = griddata(x, y, fn, X, Y, 'cubic');
        h = surf(X,Y,Tn);view(0,90);shading interp;
        colormap(p.Results.ColorMap);
        if p.Results.ColorBar
            colorbar;
        end
    elseif strcmp(p.Results.PlotType, 'vector')
        fx = TFM_results(i).traction(:,1);
        fy = TFM_results(i).traction(:,2);
        h = quiver(x, y, fx, fy, p.Results.Scale, p.Results.LineStyle, 'LineWidth', p.Results.LineWidth,...
        'MaxHeadSize', p.Results.MaxHeadSize);
    else
        error('Invalid PlotType, must be either magnitude (heatmap) or vector plot(quiver)');
    end





    if p.Results.Title
        title(p.Results.Title);
    end
    if p.Results.XLabel
        xlabel(p.Results.XLabel);
    end
    if p.Results.YLabel
        ylabel(p.Results.YLabel);
    end
    
    set(gca, 'FontSize', p.Results.FontSize);
    
    set(gca, 'YDir', 'reverse');
end