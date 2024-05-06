function drift = computeDrift(imstack,refid,window)
im1 = imstack(:,:,refid);

nframes = size(imstack,3);

for i = 1:nframes
    im2 = imstack(:,:,i);
if nargin == 2
    rowLim = [1,size(im1,1)];
    colLim =[1, size(im1,2)];
elseif nargin == 3
    lims = window;
    rowLim = [lims(2) lims(2) + lims(4)-1];
    colLim = [lims(1) lims(1) + lims(3)-1];
end

im1tmp = im1(rowLim(1):rowLim(2),colLim(1):colLim(2));
im2tmp = im2(rowLim(1):rowLim(2),colLim(1):colLim(2));

cc = normxcorr2(im1tmp,im2tmp);
[ym,xm] = find(cc == max(cc(:)));
ym = mean(ym);
xm = mean(xm);
fitRadius = 5;

[x,y] = meshgrid(xm - fitRadius : xm + fitRadius, ym - fitRadius : ym + fitRadius);
c = cc(ym - fitRadius : ym + fitRadius,xm - fitRadius : xm + fitRadius);

opts = optimset('Display','off');
peakInfo = lsqcurvefit(@Gauss2D,[1.0,1.0,xm,ym],[x(:) y(:)],c(:),[],[],opts);

x0 = peakInfo(3);
y0 = peakInfo(4);


dx = x0 - size(im1tmp,2);
dy = y0 - size(im1tmp,1);

dx = -dx;
dy = -dy;

drift(i,:) = [dx,dy];
end

end
