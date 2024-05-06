function Intensity = Gauss2D(param,pos)

Amp = param(1);
sigma = param(2);
x0 = param(3);
y0 = param(4);
Intensity = Amp * exp(-0.5*((pos(:,1) - x0).^2 + (pos(:,2) - y0).^2)/sigma^2);
end