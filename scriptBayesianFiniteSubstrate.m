clear
clc
%%
%some variables
frame =1;               %frame number in movie data sequence

thickness=10; %thickness of the substrate in micrometers

pix_durch_mu = 0.097;     %size of one pixel in micrometers 

E = 7000;      %Young's modulus in Pa
s = 0.5;       %Poisson's ratio
%extract the input data we need
input_pos   = input_data.displacement(frame).pos;
input_vec   = input_data.displacement(frame).vec;

%% select noisy region
h = figure;
quiver(gca(h),input_pos(:,1),input_pos(:,2),input_vec(:,1),input_vec(:,2),0.5,'r');
set(gca(h),'YDir','reverse');
[roi,~,~] = waitROISelection('polygon','return','backspace',h); 
%%
noise = input_vec(inpolygon(input_pos(:,1),input_pos(:,2),roi(:,1),roi(:,2)),:);
varnoise = var(noise(:));
beta = 1/varnoise;
%%
max_eck(1:2) = [max(input_pos(:,1)), max(input_pos(:,2))];
min_eck(1:2) = [min(input_pos(:,1)), min(input_pos(:,2))];
meshsize = round(sqrt((max_eck(1)-min_eck(1))*(max_eck(2)-min_eck(2))/size(input_pos,1)));


[grid_mat,i_max,j_max, X,fuu,Ftux,Ftuy,u] = fourier_X_u(input_pos,input_vec, meshsize, 1, s,[]);            
%% Calculate the optimal regularization parameter
[L,~,~] = optimal_lambda(beta,fuu,Ftux,Ftuy,1,s,meshsize,i_max, j_max,X,1);
%%

%calculate traction forces with optimal regularization parameter
[stress_vec, ~, pos, strain_vec, ~,fnorm] = fourier_TFM_reg_finite_substrate_zeropad('reg',[],input_data.displacement,frame,E,s, ...
 thickness, pix_durch_mu, meshsize, L );


%%
figure;
imagesc(fnorm');colormap jet;shading interp; 