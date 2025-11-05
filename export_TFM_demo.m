%% Example command to export a video from the output of TFM_main
% User may adjust the values as they want
load('demo_TFM_output.mat')
% load('demo02_bead_all_TFM_output.mat')

% if you have a cell image stack, load it and crop it as the same as you
% crop for the beads.
imcell_raw = tiffreadVolume('Merged_rgb.tif');
% imcell_raw = tiffreadVolume('demo02_merged_rgb.tif');
%%
% TFM_results = TF_attempt.Regularized.TFM_results;
TFM_results = TF_attempt.Bayesian.TFM_results;
TFM_settings = TF_attempt.Bayesian.TFM_settings;
meshsize = TFM_settings.meshsize;
imax = TFM_settings.i_max; jmax = TFM_settings.j_max;
roi = TF_input.settings.cropROI;
for i = 1:size(imcell_raw,3)
    if length(size(imcell_raw)) == 4 % for RGB image stack  rows-cols-frames-colors
        tmp = imcrop(squeeze(imcell_raw(:,:,i,:)),roi);
        imcell(:,:,i,:) = tmp;
    else
        tmp = imcrop(imcell_raw(:,:,i),roi); % grayscale image stack
        imcell(:,:,i) = tmp;
    end
    
    

end

se = [TFM_results.energy];
%%
% specify spatial ROI where you want to include in the video
xlim = [100 1100];
ylim = [100 1100];
% xlim = [10 460];
% ylim = [10 330];

for i = 1:length(TFM_results)
    close all
    h=figure;
    % set(h,'WindowState','maximized');
    imshow(imcrop(squeeze(imcell(:,:,i,:)),[xlim(1) ylim(1) diff(xlim) diff(ylim)]));
   % imshow(squeeze(imcell(:,:,i,:)));
    hold on;
    text(165,925,'10\mum','Color','w','FontSize',14)
    plot([150 250],[950 950],'w','LineWidth',5)
    % text(35,325,'5\mum','Color','w','FontSize',14)
    % plot([20 70],[330 330],'w','LineWidth',5);
    x = TFM_results(i).pos(:,1);
    y = TFM_results(i).pos(:,2);
    tx = TFM_results(i).traction(:,1);
    ty = TFM_results(i).traction(:,2);
    x = reshape(x,[imax,jmax]);
    y = reshape(y,[imax,jmax]);
    tx = reshape(tx,[imax,jmax]);
    ty = reshape(ty,[imax,jmax]);
    
    x = imresize(x,0.5);
    y = imresize(y,0.5);
    tx = imresize(tx,0.5);
    ty = imresize(ty,0.5);
    x = x(:); y = y(:); tx = tx(:);ty = ty(:);
    % quiver(x,y,tx,ty)
    ind = find(x > xlim(1) & x < xlim(2) & y > ylim(1) & y < ylim(2));
    % 
    % id = ind(1:11:end);


    % vector overlay
   % quiver(TFM_results(i).pos(id,1),TFM_results(i).pos(id,2),TFM_results(i).traction(id,1)/5,...
   %     TFM_results(i).traction(id,2)/5,0,'Color',[255 140 0]/255,'LineWidth',2);
        % quiver(TFM_results(i).pos(id,1)-xlim(1),TFM_results(i).pos(id,2)-ylim(1),TFM_results(i).traction(id,1),...
        % TFM_results(i).traction(id,2),2,'Color',[255 140 0]/255,'LineWidth',2);
        % quiver(x(ind)-xlim(1),y(ind)-ylim(1),tx(ind),ty(ind),1,'Color',[255 140 0]/255,'LineWidth',2);

        % quiver([x(ind);100],[y(ind);330],[tx(ind);50],[ty(ind);0],1.25,'Color',[255 140 0]/255,'LineWidth',2);
        quiver([x(ind)-xlim(1);275],[y(ind)-ylim(1);950],0.5*[tx(ind);100],0.5*[ty(ind);0],'off','Color',[255 140 0]/255,'LineWidth',2);    
    % scale bar
    text(280,925,'100Pa','Color',[255 140 0]/255,'FontSize',14);
    % quiver(275,950,100,0,1,'Color',[255 140 0]/255,'MaxHeadSize',2,'LineWidth',5)
    % text(100,325,'50Pa','Color',[255 140 0]/255,'FontSize',14)
    


    hold off
    cax = axes('Parent',h,'Position',[0.75 0.75 0.15 0.15]);% [0.6 0.75 0.15 0.15]
    plot(cax,se,'--k');
    set(cax,'ylim',[0 8]*10^-3);   % [0 13]*10^-5
    set(cax,'xlim',[0 9]);   % [0 10.5]
    set(cax,'YColor','w');
    set(cax,'FontSize',12);
    ylabel(cax,'Strain energy \muJ');
    xlabel(cax,'Time frame');
    set(cax,'XColor','w');
    hold(cax,'on')
    scatter(i,se(i),50,'or');
    hold(cax,'off');
    exportgraphics(gcf,strcat("TractionVectorOverlay_frame",sprintf("%02d",i),".eps"),"ContentType","vector");
    
    F(i) = getframe(gcf);
    pause(0.5)
end

%%
