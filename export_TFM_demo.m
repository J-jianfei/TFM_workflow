%% Example command to export a video from the output of TFM_main
% User may adjust the values as they want
% load('demo_TFM_output.mat')
% load('demo02_bead_all_TFM_output.mat')

% if you have a cell image stack, load it and crop it as the same as you
% crop for the beads.
imcell_raw = tiffreadVolume('Merged_rgb.tif');
% imcell_raw = tiffreadVolume('demo02_merged_rgb.tif');
%%
% TFM_results = TF_attempt.Regularized.TFM_results;
TFM_results = TF_attempt.Bayesian.TFM_results;
roi = TF_input.settings.driftCorrectionROI;
for i = 1:size(imcell_raw,3)
    if length(size(imcell_raw)) == 4 % for RGB image stack  rows-cols-frames-colors
        tmp = imcrop(squeeze(imcell_raw(:,:,i,:)),roi);
        imcell(:,:,i,:) = tmp;
    else
        tmp = imcrop(imcell_raw(:,:,i),roi); % grayscale image stack
        imcell(:,:,i) = tmp;
    end
    
    

end

%%
% specify spatial ROI where you want to include in the video
xlim = [100 1200];
ylim = [100 1200];
% xlim = [10 460];
% ylim = [10 330];
h=figure;
set(h,'WindowState','maximized');
for i = 1:length(TFM_results)
    imshow(squeeze(imcell(:,:,i,:)));
    hold on;
    plot([150 250],[1250 1250],'w','LineWidth',5)
    % text(35,320,'5\mum','Color','w','FontSize',14)
    % plot([20 70],[330 330],'w','LineWidth',5);
    x = TFM_results(i).pos(:,1);
    y = TFM_results(i).pos(:,2);
    
    ind = find(x > xlim(1) & x < xlim(2) & y > ylim(1) & y < ylim(2));
    
    id = ind(1:1:end);


    % vector overlay
    quiver(TFM_results(i).pos(id,1),TFM_results(i).pos(id,2),TFM_results(i).traction(id,1)/5,...
        TFM_results(i).traction(id,2)/5,0,'Color',[255 140 0]/255,'LineWidth',2);

    % scale bar
    % quiver(1000,1250,50,0, 2,'Color',[255 140 0]/255,'MaxHeadSize',2,'LineWidth',5)
    text(100,320,'100Pa','Color',[255 140 0]/255,'FontSize',14)
    quiver(100,330,20,0, 0,'Color',[255 140 0]/255,'MaxHeadSize',2,'LineWidth',5)
    hold off
    exportgraphics(gca,strcat("TractionVectorOverlay_frame",sprintf("%02d",i),".tif"),"ContentType","vector");
    F(i) = getframe(gca);
end

%%
