%%
xlim = [50 850];
ylim = [50 1100];
scale = 1;
figure;
for i = 1:length(data)
    x = data(i).x;
    y = data(i).y;
    fx = data(i).fx;
    fy = data(i).fy;
    
    ind = x>xlim(1) & x < xlim(2) & y > ylim(1) & y<ylim(2);
    imshow(squeeze(imcell(:,:,i+1,:)));
    hold on;
    quiver(x(ind),y(ind),fx(ind),fy(ind),1,'y','LineWidth',1.5,'MaxHeadSize',2);
    quiver(55,1100,100,0,'y','LineWidth',2.5,'MaxHeadSize',2);
    hold off
    
   

    exportgraphics(gca,strcat("TractionVectorOverlay_frame",sprintf("%02d",i),".png"));
    %pause(0.1)
end
%%