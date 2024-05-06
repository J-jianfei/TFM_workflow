load('demo_TFM_output.mat')
TFM_results = TF_attempt.Regularized.TFM_results;
imcell = tiffreadVolume('Merged_rgb.tif');

xlim = [100 1200];
ylim = [100 1200];

for i = 1:length(TFM_results)
    imshow(squeeze(imcell(:,:,i,:)));
    hold on;
    plot([150 250],[1250 1250],'w','LineWidth',5)
    x = TFM_results(i).pos(:,1);
    y = TFM_results(i).pos(:,2);
    
    ind = find(x > xlim(1) & x < xlim(2) & y > ylim(1) & y < ylim(2));
    
    id = ind(1:1:end);


    
    quiver(TFM_results(i).pos(id,1),TFM_results(i).pos(id,2),TFM_results(i).traction(id,1),...
        TFM_results(i).traction(id,2),2,'y','LineWidth',2);

    quiver(1000,1250,50,0, 2, 'y','MaxHeadSize',2,'LineWidth',5)
    hold off
    % exportgraphics(gca,'demo_stack_overlay.png','ContentType','vector','Append',true);
    %
    exportgraphics(gca,strcat("TractionVectorOverlay_frame",sprintf("%02d",i),".tif"),"ContentType","vector");
end

%%
