function [stress_vec, pos_corrected, pos, strain_vec, grid_mat,fnorm] = fourier_TFM_reg_finite_substrate_zeropad(filterart,bild_datei,strain,frames,E,s, depth, pix_durch_my, cluster_size, filter_param, cutoff )
    %cutoff to crop image for energy calculation
    cbnd=3;
    
    %step to plot quivers less densely
    nstep = 5;
    
    nN_pro_pix_fakt = 1/(10^3*pix_durch_my^2);
    nN_pro_my_fakt = 1/(10^3);
    
    V = 2*(1+s)/E;
    h = depth/pix_durch_my;
    
    grid_mat = [];
    for frame=frames
        u =[];
        Ftu=[];
        Ftun=[];
        Ftf=[];
        f=[]; 
        pos=[];
        un=[]; 
        strain_vec=[];
        stress_vec=[];

        %make sure all data is real to eliminate imaginary
        %rounding errors
        strain(frame).vec = real(strain(frame).vec);
        strain(frame).pos = real(strain(frame).pos);
        
        if (strncmp(filterart,'Wiener',6) | strncmp(filterart,'wiener',6))
            [grid_mat,u, i_max, j_max] = interp_vec2grid(strain(frame).pos, strain(frame).vec, cluster_size); 
            u(:,:,1) = wiener2(u(:,:,1),filter_param);
            u(:,:,2) = wiener2(u(:,:,2),filter_param);
            L = 0;
        elseif (strncmp(filterart,'Gauss',5) | strncmp(filterart,'gauss',5))
            [grid_mat,u, i_max, j_max] = interp_vec2grid(strain(frame).pos, strain(frame).vec, cluster_size); 
            gfilter = fspecial('gaussian',[cutoff,cutoff],filter_param);
            u(:,:,1) = filter2(gfilter, u(:,:,1));
            u(:,:,2) = filter2(gfilter, u(:,:,2));

            %[grid_mat,u, i_max, j_max] = filter_vec2grid(strain(frame).pos, strain(frame).vec, filter_param, cutoff, cluster_size);
            L = 0;
        elseif (strncmp(filterart,'reg',3) | strncmp(filterart,'REG',3))
            [grid_mat,u, i_max, j_max] = interp_vec2grid(strain(frame).pos, strain(frame).vec, cluster_size,grid_mat); 
            L = filter_param*V^2; 
        else
            [grid_mat,u, i_max, j_max] = interp_vec2grid(strain(frame).pos, strain(frame).vec, cluster_size, grid_mat); 
            L = 0;
        end

        %u(:,:,1) = u(:,:,1)-mean(mean(u(:,:,1)));
        %u(:,:,2) = u(:,:,2)-mean(mean(u(:,:,2)));
        
        i_pad_space = ceil(i_max/2);
        j_pad_space = ceil(j_max/2);
        u_x = [zeros(i_pad_space, j_max + 2*j_pad_space); zeros(i_max, j_pad_space),u(:,:,1), zeros(i_max, j_pad_space); zeros(i_pad_space,j_max + 2* j_pad_space)];
        u_y = [zeros(i_pad_space, j_max + 2*j_pad_space); zeros(i_max, j_pad_space),u(:,:,2), zeros(i_max, j_pad_space); zeros(i_pad_space,j_max + 2* j_pad_space)];    

        kx_vec = 2*pi/(i_max + 2*i_pad_space)/cluster_size.*[0:((i_max+2*i_pad_space)/2) (-((i_max+2*i_pad_space)/2-1):-1)];
        ky_vec = 2*pi/(j_max + 2*j_pad_space)/cluster_size.*[0:((j_max+2*j_pad_space)/2) (-((j_max+2*j_pad_space)/2-1):-1)];

        kx = repmat(kx_vec',1,(j_max + 2*j_pad_space));
        ky = repmat(ky_vec,(i_max + 2*i_pad_space),1);

        kx(1,1) = 1;
        ky(1,1) = 1;

        X = i_max*cluster_size/2;
        Y = j_max*cluster_size/2; 
        
        Ginv_xx =(-16).*(kx.^2+ky.^2).^(-1/2).*V.*cosh(h.*(kx.^2+ky.^2).^( ...
          1/2)).^2.*(kx.^2.*L+ky.^2.*L+(-1).*V.^2+(kx.^2.*L+ky.^2.*L+ ...
          V.^2).*cosh(2.*h.*(kx.^2+ky.^2).^(1/2))).^(-1).*(59.*kx.^2.* ...
          L+40.*h.^2.*kx.^4.*L+8.*h.^4.*kx.^6.*L+59.*ky.^2.*L+80.* ...
          h.^2.*kx.^2.*ky.^2.*L+24.*h.^4.*kx.^4.*ky.^2.*L+40.*h.^2.* ...
          ky.^4.*L+24.*h.^4.*kx.^2.*ky.^4.*L+8.*h.^4.*ky.^6.*L+(-264) ...
          .*kx.^2.*L.*s+(-96).*h.^2.*kx.^4.*L.*s+(-264).*ky.^2.*L.*s+( ...
          -192).*h.^2.*kx.^2.*ky.^2.*L.*s+(-96).*h.^2.*ky.^4.*L.*s+ ...
          464.*kx.^2.*L.*s.^2+64.*h.^2.*kx.^4.*L.*s.^2+464.*ky.^2.*L.* ...
          s.^2+128.*h.^2.*kx.^2.*ky.^2.*L.*s.^2+64.*h.^2.*ky.^4.*L.* ...
          s.^2+(-384).*kx.^2.*L.*s.^3+(-384).*ky.^2.*L.*s.^3+128.* ...
          kx.^2.*L.*s.^4+128.*ky.^2.*L.*s.^4+(-9).*V.^2+8.*h.^2.* ...
          kx.^2.*V.^2+8.*h.^2.*ky.^2.*V.^2+42.*s.*V.^2+(-16).*h.^2.* ...
          kx.^2.*s.*V.^2+(-16).*h.^2.*ky.^2.*s.*V.^2+(-73).*s.^2.* ...
          V.^2+8.*h.^2.*kx.^2.*s.^2.*V.^2+8.*h.^2.*ky.^2.*s.^2.*V.^2+ ...
          56.*s.^3.*V.^2+(-16).*s.^4.*V.^2+(-4).*(kx.^2+ky.^2).*L.*(( ...
          -3)+4.*s).*(5+2.*h.^2.*(kx.^2+ky.^2)+(-12).*s+8.*s.^2).* ...
          cosh(2.*h.*(kx.^2+ky.^2).^(1/2))+(3+(-4).*s).^2.*(kx.^2.*L+ ...
          ky.^2.*L+((-1)+s).^2.*V.^2).*cosh(4.*h.*(kx.^2+ky.^2).^(1/2) ...
          )+24.*h.*(kx.^2+ky.^2).^(1/2).*V.^2.*sinh(2.*h.*(kx.^2+ ...
          ky.^2).^(1/2))+(-80).*h.*(kx.^2+ky.^2).^(1/2).*s.*V.^2.* ...
          sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+88.*h.*(kx.^2+ky.^2).^(1/2) ...
          .*s.^2.*V.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-32).*h.*( ...
          kx.^2+ky.^2).^(1/2).*s.^3.*V.^2.*sinh(2.*h.*(kx.^2+ky.^2).^( ...
          1/2))).^(-1).*((-1).*h.*kx.^4.*(kx.^2+ky.^2).^(1/2).*L+(-1) ...
          .*h.^3.*kx.^6.*(kx.^2+ky.^2).^(1/2).*L+(-1).*h.*kx.^2.* ...
          ky.^2.*(kx.^2+ky.^2).^(1/2).*L+(-2).*h.^3.*kx.^4.*ky.^2.*( ...
          kx.^2+ky.^2).^(1/2).*L+(-1).*h.^3.*kx.^2.*ky.^4.*(kx.^2+ ...
          ky.^2).^(1/2).*L+5.*h.*kx.^4.*(kx.^2+ky.^2).^(1/2).*L.*s+ ...
          h.^3.*kx.^6.*(kx.^2+ky.^2).^(1/2).*L.*s+5.*h.*kx.^2.*ky.^2.* ...
          (kx.^2+ky.^2).^(1/2).*L.*s+2.*h.^3.*kx.^4.*ky.^2.*(kx.^2+ ...
          ky.^2).^(1/2).*L.*s+h.^3.*kx.^2.*ky.^4.*(kx.^2+ky.^2).^(1/2) ...
          .*L.*s+(-8).*h.*kx.^4.*(kx.^2+ky.^2).^(1/2).*L.*s.^2+(-8).* ...
          h.*kx.^2.*ky.^2.*(kx.^2+ky.^2).^(1/2).*L.*s.^2+4.*h.*kx.^4.* ...
          (kx.^2+ky.^2).^(1/2).*L.*s.^3+4.*h.*kx.^2.*ky.^2.*(kx.^2+ ...
          ky.^2).^(1/2).*L.*s.^3+(-1).*h.*kx.^2.*(kx.^2+ky.^2).^(3/2) ...
          .*L.*(3+(-7).*s+4.*s.^2).*cosh(h.*(kx.^2+ky.^2).^(1/2)).^2+( ...
          kx.^2+ky.^2).*L.*((-1).*ky.^2+kx.^2.*((-1)+s)).*(3+(-4).*s) ...
          .^2.*cosh(h.*(kx.^2+ky.^2).^(1/2)).^3.*sinh(h.*(kx.^2+ky.^2) ...
          .^(1/2))+(kx.^2+(-1).*ky.^2.*((-1)+s)).*(3+(-4).*s).^2.*(( ...
          -1)+s).*V.^2.*cosh(h.*(kx.^2+ky.^2).^(1/2)).*sinh(h.*(kx.^2+ ...
          ky.^2).^(1/2)).^3+(-3/2).*kx.^4.*L.*sinh(2.*h.*(kx.^2+ky.^2) ...
          .^(1/2))+(-3/2).*h.^2.*kx.^6.*L.*sinh(2.*h.*(kx.^2+ky.^2).^( ...
          1/2))+(-9/2).*kx.^2.*ky.^2.*L.*sinh(2.*h.*(kx.^2+ky.^2).^( ...
          1/2))+(-6).*h.^2.*kx.^4.*ky.^2.*L.*sinh(2.*h.*(kx.^2+ky.^2) ...
          .^(1/2))+(-3).*ky.^4.*L.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+( ...
          -15/2).*h.^2.*kx.^2.*ky.^4.*L.*sinh(2.*h.*(kx.^2+ky.^2).^( ...
          1/2))+(-3).*h.^2.*ky.^6.*L.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2)) ...
          +(19/2).*kx.^4.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(7/2) ...
          .*h.^2.*kx.^6.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(51/2) ...
          .*kx.^2.*ky.^2.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+11.* ...
          h.^2.*kx.^4.*ky.^2.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+ ...
          16.*ky.^4.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(23/2).* ...
          h.^2.*kx.^2.*ky.^4.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+ ...
          4.*h.^2.*ky.^6.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-22) ...
          .*kx.^4.*L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-2).* ...
          h.^2.*kx.^6.*L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-50) ...
          .*kx.^2.*ky.^2.*L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+( ...
          -4).*h.^2.*kx.^4.*ky.^2.*L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2) ...
          .^(1/2))+(-28).*ky.^4.*L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^( ...
          1/2))+(-2).*h.^2.*kx.^2.*ky.^4.*L.*s.^2.*sinh(2.*h.*(kx.^2+ ...
          ky.^2).^(1/2))+22.*kx.^4.*L.*s.^3.*sinh(2.*h.*(kx.^2+ky.^2) ...
          .^(1/2))+38.*kx.^2.*ky.^2.*L.*s.^3.*sinh(2.*h.*(kx.^2+ky.^2) ...
          .^(1/2))+16.*ky.^4.*L.*s.^3.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2) ...
          )+(-8).*kx.^4.*L.*s.^4.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+( ...
          -8).*kx.^2.*ky.^2.*L.*s.^4.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2)) ...
          +(-1).*kx.^2.*ky.^2.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-2).* ...
          h.^2.*kx.^4.*ky.^2.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-1).* ...
          h.^4.*kx.^6.*ky.^2.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-1).* ...
          ky.^4.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-4).*h.^2.*kx.^2.* ...
          ky.^4.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-3).*h.^4.*kx.^4.* ...
          ky.^4.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-2).*h.^2.*ky.^6.* ...
          L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-3).*h.^4.*kx.^2.*ky.^6.* ...
          L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-1).*h.^4.*ky.^8.*L.*tanh( ...
          h.*(kx.^2+ky.^2).^(1/2))+8.*kx.^2.*ky.^2.*L.*s.*tanh(h.*( ...
          kx.^2+ky.^2).^(1/2))+8.*h.^2.*kx.^4.*ky.^2.*L.*s.*tanh(h.*( ...
          kx.^2+ky.^2).^(1/2))+8.*ky.^4.*L.*s.*tanh(h.*(kx.^2+ky.^2) ...
          .^(1/2))+16.*h.^2.*kx.^2.*ky.^4.*L.*s.*tanh(h.*(kx.^2+ky.^2) ...
          .^(1/2))+8.*h.^2.*ky.^6.*L.*s.*tanh(h.*(kx.^2+ky.^2).^(1/2)) ...
          +(-24).*kx.^2.*ky.^2.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)) ...
          +(-8).*h.^2.*kx.^4.*ky.^2.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2))+(-24).*ky.^4.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+( ...
          -16).*h.^2.*kx.^2.*ky.^4.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2))+(-8).*h.^2.*ky.^6.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2))+32.*kx.^2.*ky.^2.*L.*s.^3.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2))+32.*ky.^4.*L.*s.^3.*tanh(h.*(kx.^2+ky.^2).^(1/2))+( ...
          -16).*kx.^2.*ky.^2.*L.*s.^4.*tanh(h.*(kx.^2+ky.^2).^(1/2))+( ...
          -16).*ky.^4.*L.*s.^4.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-1).* ...
          h.^2.*kx.^2.*ky.^2.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-1) ...
          .*h.^2.*ky.^4.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+2.*h.^2.* ...
          kx.^2.*ky.^2.*s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+2.* ...
          h.^2.*ky.^4.*s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-1).* ...
          h.^2.*kx.^2.*ky.^2.*s.^2.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2) ...
          )+(-1).*h.^2.*ky.^4.*s.^2.*V.^2.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2))+(-1).*(3+(-7).*s+4.*s.^2).*V.^2.*sinh(h.*(kx.^2+ky.^2) ...
          .^(1/2)).*(h.*(kx.^2+ky.^2).^(1/2).*(kx.^2+(-2).*ky.^2.*(( ...
          -1)+s)).*cosh(h.*(kx.^2+ky.^2).^(1/2))+kx.^2.*(h.^2.*(kx.^2+ ...
          ky.^2)+(1+(-2).*s).^2).*sinh(h.*(kx.^2+ky.^2).^(1/2))).* ...
          tanh(h.*(kx.^2+ky.^2).^(1/2))+(-1).*h.*kx.^2.*(kx.^2+ky.^2) ...
          .^(1/2).*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)).^2+(-1).*h.^3.* ...
          kx.^4.*(kx.^2+ky.^2).^(1/2).*V.^2.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2)).^2+(-1).*h.^3.*kx.^2.*ky.^2.*(kx.^2+ky.^2).^(1/2).* ...
          V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)).^2+5.*h.*kx.^2.*(kx.^2+ ...
          ky.^2).^(1/2).*s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)).^2+ ...
          h.^3.*kx.^4.*(kx.^2+ky.^2).^(1/2).*s.*V.^2.*tanh(h.*(kx.^2+ ...
          ky.^2).^(1/2)).^2+h.^3.*kx.^2.*ky.^2.*(kx.^2+ky.^2).^(1/2).* ...
          s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)).^2+(-8).*h.*kx.^2.*( ...
          kx.^2+ky.^2).^(1/2).*s.^2.*V.^2.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2)).^2+4.*h.*kx.^2.*(kx.^2+ky.^2).^(1/2).*s.^3.*V.^2.* ...
          tanh(h.*(kx.^2+ky.^2).^(1/2)).^2);

        Ginv_yy =8.*(kx.^2+ky.^2).^(-1/2).*V.*cosh(h.*(kx.^2+ky.^2).^(1/2)) ...
          .^2.*(kx.^2.*L+ky.^2.*L+(-1).*V.^2+(kx.^2.*L+ky.^2.*L+V.^2) ...
          .*cosh(2.*h.*(kx.^2+ky.^2).^(1/2))).^(-1).*(59.*kx.^2.*L+ ...
          40.*h.^2.*kx.^4.*L+8.*h.^4.*kx.^6.*L+59.*ky.^2.*L+80.*h.^2.* ...
          kx.^2.*ky.^2.*L+24.*h.^4.*kx.^4.*ky.^2.*L+40.*h.^2.*ky.^4.* ...
          L+24.*h.^4.*kx.^2.*ky.^4.*L+8.*h.^4.*ky.^6.*L+(-264).* ...
          kx.^2.*L.*s+(-96).*h.^2.*kx.^4.*L.*s+(-264).*ky.^2.*L.*s+( ...
          -192).*h.^2.*kx.^2.*ky.^2.*L.*s+(-96).*h.^2.*ky.^4.*L.*s+ ...
          464.*kx.^2.*L.*s.^2+64.*h.^2.*kx.^4.*L.*s.^2+464.*ky.^2.*L.* ...
          s.^2+128.*h.^2.*kx.^2.*ky.^2.*L.*s.^2+64.*h.^2.*ky.^4.*L.* ...
          s.^2+(-384).*kx.^2.*L.*s.^3+(-384).*ky.^2.*L.*s.^3+128.* ...
          kx.^2.*L.*s.^4+128.*ky.^2.*L.*s.^4+(-9).*V.^2+8.*h.^2.* ...
          kx.^2.*V.^2+8.*h.^2.*ky.^2.*V.^2+42.*s.*V.^2+(-16).*h.^2.* ...
          kx.^2.*s.*V.^2+(-16).*h.^2.*ky.^2.*s.*V.^2+(-73).*s.^2.* ...
          V.^2+8.*h.^2.*kx.^2.*s.^2.*V.^2+8.*h.^2.*ky.^2.*s.^2.*V.^2+ ...
          56.*s.^3.*V.^2+(-16).*s.^4.*V.^2+(-4).*(kx.^2+ky.^2).*L.*(( ...
          -3)+4.*s).*(5+2.*h.^2.*(kx.^2+ky.^2)+(-12).*s+8.*s.^2).* ...
          cosh(2.*h.*(kx.^2+ky.^2).^(1/2))+(3+(-4).*s).^2.*(kx.^2.*L+ ...
          ky.^2.*L+((-1)+s).^2.*V.^2).*cosh(4.*h.*(kx.^2+ky.^2).^(1/2) ...
          )+24.*h.*(kx.^2+ky.^2).^(1/2).*V.^2.*sinh(2.*h.*(kx.^2+ ...
          ky.^2).^(1/2))+(-80).*h.*(kx.^2+ky.^2).^(1/2).*s.*V.^2.* ...
          sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+88.*h.*(kx.^2+ky.^2).^(1/2) ...
          .*s.^2.*V.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-32).*h.*( ...
          kx.^2+ky.^2).^(1/2).*s.^3.*V.^2.*sinh(2.*h.*(kx.^2+ky.^2).^( ...
          1/2))).^(-1).*(2.*h.*kx.^2.*ky.^2.*(kx.^2+ky.^2).^(1/2).*L+ ...
          2.*h.^3.*kx.^4.*ky.^2.*(kx.^2+ky.^2).^(1/2).*L+2.*h.*ky.^4.* ...
          (kx.^2+ky.^2).^(1/2).*L+4.*h.^3.*kx.^2.*ky.^4.*(kx.^2+ky.^2) ...
          .^(1/2).*L+2.*h.^3.*ky.^6.*(kx.^2+ky.^2).^(1/2).*L+(-10).* ...
          h.*kx.^2.*ky.^2.*(kx.^2+ky.^2).^(1/2).*L.*s+(-2).*h.^3.* ...
          kx.^4.*ky.^2.*(kx.^2+ky.^2).^(1/2).*L.*s+(-10).*h.*ky.^4.*( ...
          kx.^2+ky.^2).^(1/2).*L.*s+(-4).*h.^3.*kx.^2.*ky.^4.*(kx.^2+ ...
          ky.^2).^(1/2).*L.*s+(-2).*h.^3.*ky.^6.*(kx.^2+ky.^2).^(1/2) ...
          .*L.*s+16.*h.*kx.^2.*ky.^2.*(kx.^2+ky.^2).^(1/2).*L.*s.^2+ ...
          16.*h.*ky.^4.*(kx.^2+ky.^2).^(1/2).*L.*s.^2+(-8).*h.*kx.^2.* ...
          ky.^2.*(kx.^2+ky.^2).^(1/2).*L.*s.^3+(-8).*h.*ky.^4.*(kx.^2+ ...
          ky.^2).^(1/2).*L.*s.^3+2.*h.*ky.^2.*(kx.^2+ky.^2).^(3/2).* ...
          L.*(3+(-7).*s+4.*s.^2).*cosh(h.*(kx.^2+ky.^2).^(1/2)).^2+2.* ...
          (kx.^2+ky.^2).*L.*(kx.^2+(-1).*ky.^2.*((-1)+s)).*(3+(-4).*s) ...
          .^2.*cosh(h.*(kx.^2+ky.^2).^(1/2)).^3.*sinh(h.*(kx.^2+ky.^2) ...
          .^(1/2))+(-2).*(ky.^2+(-1).*kx.^2.*((-1)+s)).*(3+(-4).*s) ...
          .^2.*((-1)+s).*V.^2.*cosh(h.*(kx.^2+ky.^2).^(1/2)).*sinh(h.* ...
          (kx.^2+ky.^2).^(1/2)).^3+6.*kx.^4.*L.*sinh(2.*h.*(kx.^2+ ...
          ky.^2).^(1/2))+6.*h.^2.*kx.^6.*L.*sinh(2.*h.*(kx.^2+ky.^2) ...
          .^(1/2))+9.*kx.^2.*ky.^2.*L.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2) ...
          )+15.*h.^2.*kx.^4.*ky.^2.*L.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2) ...
          )+3.*ky.^4.*L.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+12.*h.^2.* ...
          kx.^2.*ky.^4.*L.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+3.*h.^2.* ...
          ky.^6.*L.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-32).*kx.^4.*L.* ...
          s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-8).*h.^2.*kx.^6.*L.* ...
          s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-51).*kx.^2.*ky.^2.*L.* ...
          s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-23).*h.^2.*kx.^4.* ...
          ky.^2.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-19).*ky.^4.* ...
          L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-22).*h.^2.*kx.^2.* ...
          ky.^4.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-7).*h.^2.* ...
          ky.^6.*L.*s.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+56.*kx.^4.*L.* ...
          s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+100.*kx.^2.*ky.^2.* ...
          L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+4.*h.^2.*kx.^4.* ...
          ky.^2.*L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+44.*ky.^4.* ...
          L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+8.*h.^2.*kx.^2.* ...
          ky.^4.*L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+4.*h.^2.* ...
          ky.^6.*L.*s.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-32).* ...
          kx.^4.*L.*s.^3.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-76).* ...
          kx.^2.*ky.^2.*L.*s.^3.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+( ...
          -44).*ky.^4.*L.*s.^3.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+16.* ...
          kx.^2.*ky.^2.*L.*s.^4.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+16.* ...
          ky.^4.*L.*s.^4.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+2.*kx.^4.* ...
          L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+4.*h.^2.*kx.^6.*L.*tanh(h.* ...
          (kx.^2+ky.^2).^(1/2))+2.*h.^4.*kx.^8.*L.*tanh(h.*(kx.^2+ ...
          ky.^2).^(1/2))+2.*kx.^2.*ky.^2.*L.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2))+8.*h.^2.*kx.^4.*ky.^2.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2) ...
          )+6.*h.^4.*kx.^6.*ky.^2.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+ ...
          4.*h.^2.*kx.^2.*ky.^4.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+6.* ...
          h.^4.*kx.^4.*ky.^4.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+2.* ...
          h.^4.*kx.^2.*ky.^6.*L.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-16).* ...
          kx.^4.*L.*s.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-16).*h.^2.* ...
          kx.^6.*L.*s.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-16).*kx.^2.* ...
          ky.^2.*L.*s.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-32).*h.^2.* ...
          kx.^4.*ky.^2.*L.*s.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-16).* ...
          h.^2.*kx.^2.*ky.^4.*L.*s.*tanh(h.*(kx.^2+ky.^2).^(1/2))+48.* ...
          kx.^4.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+16.*h.^2.* ...
          kx.^6.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+48.*kx.^2.* ...
          ky.^2.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+32.*h.^2.* ...
          kx.^4.*ky.^2.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+16.* ...
          h.^2.*kx.^2.*ky.^4.*L.*s.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+( ...
          -64).*kx.^4.*L.*s.^3.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-64).* ...
          kx.^2.*ky.^2.*L.*s.^3.*tanh(h.*(kx.^2+ky.^2).^(1/2))+32.* ...
          kx.^4.*L.*s.^4.*tanh(h.*(kx.^2+ky.^2).^(1/2))+32.*kx.^2.* ...
          ky.^2.*L.*s.^4.*tanh(h.*(kx.^2+ky.^2).^(1/2))+2.*h.^2.* ...
          kx.^4.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+2.*h.^2.*kx.^2.* ...
          ky.^2.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-4).*h.^2.* ...
          kx.^4.*s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+(-4).*h.^2.* ...
          kx.^2.*ky.^2.*s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+2.* ...
          h.^2.*kx.^4.*s.^2.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+2.* ...
          h.^2.*kx.^2.*ky.^2.*s.^2.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2) ...
          )+2.*(3+(-7).*s+4.*s.^2).*V.^2.*sinh(h.*(kx.^2+ky.^2).^(1/2) ...
          ).*((-1).*h.*(kx.^2+ky.^2).^(1/2).*((-1).*ky.^2+2.*kx.^2.*(( ...
          -1)+s)).*cosh(h.*(kx.^2+ky.^2).^(1/2))+ky.^2.*(h.^2.*(kx.^2+ ...
          ky.^2)+(1+(-2).*s).^2).*sinh(h.*(kx.^2+ky.^2).^(1/2))).* ...
          tanh(h.*(kx.^2+ky.^2).^(1/2))+2.*h.*ky.^2.*(kx.^2+ky.^2).^( ...
          1/2).*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)).^2+2.*h.^3.* ...
          kx.^2.*ky.^2.*(kx.^2+ky.^2).^(1/2).*V.^2.*tanh(h.*(kx.^2+ ...
          ky.^2).^(1/2)).^2+2.*h.^3.*ky.^4.*(kx.^2+ky.^2).^(1/2).* ...
          V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)).^2+(-10).*h.*ky.^2.*( ...
          kx.^2+ky.^2).^(1/2).*s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)) ...
          .^2+(-2).*h.^3.*kx.^2.*ky.^2.*(kx.^2+ky.^2).^(1/2).*s.* ...
          V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)).^2+(-2).*h.^3.*ky.^4.*( ...
          kx.^2+ky.^2).^(1/2).*s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)) ...
          .^2+16.*h.*ky.^2.*(kx.^2+ky.^2).^(1/2).*s.^2.*V.^2.*tanh(h.* ...
          (kx.^2+ky.^2).^(1/2)).^2+(-8).*h.*ky.^2.*(kx.^2+ky.^2).^( ...
          1/2).*s.^3.*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2)).^2);

        Ginv_xy = (-16).*kx.*ky.*(kx.^2+ky.^2).^(-1/2).*V.*cosh(h.*(kx.^2+ ...
          ky.^2).^(1/2)).^2.*(kx.^2.*L+ky.^2.*L+(-1).*V.^2+(kx.^2.*L+ ...
          ky.^2.*L+V.^2).*cosh(2.*h.*(kx.^2+ky.^2).^(1/2))).^(-1).*( ...
          59.*kx.^2.*L+40.*h.^2.*kx.^4.*L+8.*h.^4.*kx.^6.*L+59.* ...
          ky.^2.*L+80.*h.^2.*kx.^2.*ky.^2.*L+24.*h.^4.*kx.^4.*ky.^2.* ...
          L+40.*h.^2.*ky.^4.*L+24.*h.^4.*kx.^2.*ky.^4.*L+8.*h.^4.* ...
          ky.^6.*L+(-264).*kx.^2.*L.*s+(-96).*h.^2.*kx.^4.*L.*s+(-264) ...
          .*ky.^2.*L.*s+(-192).*h.^2.*kx.^2.*ky.^2.*L.*s+(-96).*h.^2.* ...
          ky.^4.*L.*s+464.*kx.^2.*L.*s.^2+64.*h.^2.*kx.^4.*L.*s.^2+ ...
          464.*ky.^2.*L.*s.^2+128.*h.^2.*kx.^2.*ky.^2.*L.*s.^2+64.* ...
          h.^2.*ky.^4.*L.*s.^2+(-384).*kx.^2.*L.*s.^3+(-384).*ky.^2.* ...
          L.*s.^3+128.*kx.^2.*L.*s.^4+128.*ky.^2.*L.*s.^4+(-9).*V.^2+ ...
          8.*h.^2.*kx.^2.*V.^2+8.*h.^2.*ky.^2.*V.^2+42.*s.*V.^2+(-16) ...
          .*h.^2.*kx.^2.*s.*V.^2+(-16).*h.^2.*ky.^2.*s.*V.^2+(-73).* ...
          s.^2.*V.^2+8.*h.^2.*kx.^2.*s.^2.*V.^2+8.*h.^2.*ky.^2.*s.^2.* ...
          V.^2+56.*s.^3.*V.^2+(-16).*s.^4.*V.^2+(-4).*(kx.^2+ky.^2).* ...
          L.*((-3)+4.*s).*(5+2.*h.^2.*(kx.^2+ky.^2)+(-12).*s+8.*s.^2) ...
          .*cosh(2.*h.*(kx.^2+ky.^2).^(1/2))+(3+(-4).*s).^2.*(kx.^2.* ...
          L+ky.^2.*L+((-1)+s).^2.*V.^2).*cosh(4.*h.*(kx.^2+ky.^2).^( ...
          1/2))+24.*h.*(kx.^2+ky.^2).^(1/2).*V.^2.*sinh(2.*h.*(kx.^2+ ...
          ky.^2).^(1/2))+(-80).*h.*(kx.^2+ky.^2).^(1/2).*s.*V.^2.* ...
          sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+88.*h.*(kx.^2+ky.^2).^(1/2) ...
          .*s.^2.*V.^2.*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(-32).*h.*( ...
          kx.^2+ky.^2).^(1/2).*s.^3.*V.^2.*sinh(2.*h.*(kx.^2+ky.^2).^( ...
          1/2))).^(-1).*(h.*(kx.^2+ky.^2).^(1/2).*((-1)+s)+(-1/2).*s.* ...
          ((-3)+4.*s).*sinh(2.*h.*(kx.^2+ky.^2).^(1/2))+(h.^2.*(kx.^2+ ...
          ky.^2)+(1+(-2).*s).^2).*tanh(h.*(kx.^2+ky.^2).^(1/2))).*( ...
          kx.^2.*L+h.^2.*kx.^4.*L+ky.^2.*L+2.*h.^2.*kx.^2.*ky.^2.*L+ ...
          h.^2.*ky.^4.*L+(-4).*kx.^2.*L.*s+(-4).*ky.^2.*L.*s+4.* ...
          kx.^2.*L.*s.^2+4.*ky.^2.*L.*s.^2+(-1).*(kx.^2+ky.^2).*L.*(( ...
          -3)+4.*s).*cosh(h.*(kx.^2+ky.^2).^(1/2)).^2+(-1).*(3+(-7).* ...
          s+4.*s.^2).*V.^2.*sinh(h.*(kx.^2+ky.^2).^(1/2)).^2+(-1).*h.* ...
          (kx.^2+ky.^2).^(1/2).*V.^2.*tanh(h.*(kx.^2+ky.^2).^(1/2))+ ...
          h.*(kx.^2+ky.^2).^(1/2).*s.*V.^2.*tanh(h.*(kx.^2+ky.^2).^( ...
          1/2)));

        Ginv_xx(1,1) = 0;
        Ginv_yy(1,1) = 0;
        Ginv_xy(1,1) = 0;

        %Ginv_xy((i_max+2*i_pad_space)/2+1,:) = 0;
        %Ginv_xy(:,(j_max+2*j_pad_space)/2+1) = 0;


        Ftu(:,:,1) = fft2(u_x);
        Ftu(:,:,2) = fft2(u_y);

        Ftf(:,:,1) = Ginv_xx.*Ftu(:,:,1) + Ginv_xy.*Ftu(:,:,2);
        Ftf(:,:,2) = Ginv_xy.*Ftu(:,:,1) + Ginv_yy.*Ftu(:,:,2);

        %Ftf(1,1,1)
        %Ftf(1,1,2)
        
        f_x = ifft2(Ftf(:,:,1), 'symmetric');
        f_y = ifft2(Ftf(:,:,2), 'symmetric');

        %mean(mean(f_x))
        %mean(mean(f_y))
        
        f(:,:,1) = f_x((i_pad_space+1):(i_pad_space+i_max), (j_pad_space+1):(j_pad_space + j_max));
        f(:,:,2) = f_y((i_pad_space+1):(i_pad_space+i_max), (j_pad_space+1):(j_pad_space + j_max));    

        %mean(mean(f(:,:,1)))
        %mean(mean(f(:,:,2)))
        
        pos(:,1) = reshape(grid_mat(:,:,1),i_max*j_max,1);
        pos(:,2) = reshape(grid_mat(:,:,2),i_max*j_max,1);

        strain_vec(:,1) = reshape(u(:,:,1),i_max*j_max,1);
        strain_vec(:,2) = reshape(u(:,:,2),i_max*j_max,1);

        pos_corrected = pos + strain_vec;

        stress_vec(:,1) = reshape(f(:,:,1),i_max*j_max,1);
        stress_vec(:,2) = reshape(f(:,:,2),i_max*j_max,1);

        fnorm_noedge = (f(2:end-1,2:end-1,2).^2 + f(2:end-1,2:end-1,1).^2).^0.5;
        fnorm = (f(:,:,2).^2 + f(:,:,1).^2).^0.5;

        max_traction = max(max(fnorm_noedge));
        mean_abs_traction = sum(sum(fnorm_noedge))/i_max/j_max;
        mean_abs_strain = sum(sum((u(:,:,2).^2 + u(:,:,1).^2).^0.5))/i_max/j_max;
        
        energy = 1/2*sum(sum(u(cbnd:(end-cbnd+1),cbnd:(end-cbnd+1),1).*f(cbnd:(end-cbnd+1),cbnd:(end-cbnd+1),1) + u(cbnd:(end-cbnd+1),cbnd:(end-cbnd+1),2).*f(cbnd:(end-cbnd+1),cbnd:(end-cbnd+1),2)))*(cluster_size)^2*pix_durch_my^3/10^6;
        
        disp('-------------------------------------------------------------------------------');
        disp(['Ft-displacements at Nyquist frequency: ', num2str([Ftu(i_max/2 +1, j_max/2 +1,1), Ftu(i_max/2 +1, j_max/2 +1,2)])]);
        disp(['Ft-displacements at Nyquist frequency (relativ to Maximum): ', num2str([Ftu(i_max/2 +1, j_max/2 +1,1), Ftu(i_max/2 +1, j_max/2 +1,2)]/max(max(max(Ftu(:,:,1:2)))))]);
        disp('-------------------------------------------------------------------------------');
        disp(['Maximum Traction [Pa],[nN/my^2],[nN/pix^2]: ', num2str(max_traction,'%10.2f'),'  ',num2str(max_traction*nN_pro_my_fakt, '%3.3f'),'  ',num2str(max_traction*nN_pro_pix_fakt,'%10.2f')]);
        disp(['Mean absolute Traction [Pa],[nN/my^2],[nN/pix^2]: ', num2str(mean_abs_traction,'%10.2f'),'  ',num2str(mean_abs_traction*nN_pro_my_fakt, '%3.3f'),'  ',num2str(mean_abs_traction*nN_pro_pix_fakt,'%10.2f')]);
        disp(['Mean absolute displacement [pix],[my]: ', num2str(mean_abs_strain,'%3.3f'),'  ',num2str(mean_abs_strain*pix_durch_my, '%4.4f')]);
        disp(['Potential energy [pJ]: ', num2str(energy,'%10.4f') ]);
        disp(sprintf('\n'))

        TFM_results(frame).pos = pos_corrected;
        TFM_results(frame).vec = strain_vec;
        TFM_results(frame).traction = stress_vec;
        TFM_results(frame).traction_magnitude = fnorm;
        TFM_results(frame).energy = energy;
        TFM_results(frame).traction_grid = f;
        TFM_results(frame).traction_grid_pos = grid_mat;
        TFM_results(frame).vec_orig(:,1) =  reshape(u(:,:,1),i_max*j_max,1);
        TFM_results(frame).vec_orig(:,2) =  reshape(u(:,:,2),i_max*j_max,1);
        TFM_results(frame).pos_orig =  pos;
    end
        
    if ~isempty(bild_datei)
        
        bild = imread(bild_datei);
        
        figure, imagesc(bild); axis equal; hold on;colormap gray;
        
        %quiver(grid_mat(1:nstep:end,1:nstep:end,1), grid_mat(1:nstep:end,1:nstep:end,2), pix_durch_my*u(1:nstep:end,1:nstep:end,1), pix_durch_my*u(1:nstep:end,1:nstep:end,2),3,'b');
        quiver(strain(frame).pos(:,1),strain(frame).pos(:,2),pix_durch_my*strain(frame).vec(:,1),pix_durch_my*strain(frame).vec(:,2),3,'g'), hold off;
        %quiver(strain(frame).pos(:,1),strain(frame).pos(:,2),strain(frame).vec(:,1),strain(frame).vec(:,2),2,'g'), hold off;
        title('Strain data. Interpolated field in blue.');
       
        
        %fact = 100;
        %quiver(grid_mat(1:nstep:end,1:nstep:end,1), grid_mat(1:nstep:end,1:nstep:end,2), fact*pix_durch_my*u(1:nstep:end,1:nstep:end,1), fact*pix_durch_my*u(1:nstep:end,1:nstep:end,2),'r','AutoScale','off');


        
        h_vec = figure; imagesc(bild); hold on; colormap gray, axis equal; 
        quiver(pos_corrected(:,1),pos_corrected(:,2),stress_vec(:,1),stress_vec(:,2),3,'r');
        title('Full stress data with locations corrected for substrate displacement');        
        %saveas(h_vec,['vec_',num2str(frame),'.tif'],'tiffn');

        %h_mag=figure;
        %colormap default;
        %surf(grid_mat(:,:,1), grid_mat(:,:,2), fnorm),view(0,90), shading interp, axis equal;
        %set(gca, 'DataAspectRatio', [1,1,10],'YDir','reverse'), colorbar; hold off;
        %saveas(h_mag,['mag_',num2str(frame),'.tif'],'tiffn');

        h_mag=figure;    
        colormap default;
        hold on;
        surf(grid_mat(:,:,1),grid_mat(:,:,2), fnorm),view(0,90), shading interp, axis equal;
        set(gca, 'DataAspectRatio', [1,1,10],'YDir','reverse'), colorbar;
        quiver3(grid_mat(1:nstep:end,1:nstep:end,1), grid_mat(1:nstep:end,1:nstep:end,2),(max(max(fnorm))+1)*ones(size(f(1:nstep:end,1:nstep:end,1))),f(1:nstep:end,1:nstep:end,1),f(1:nstep:end,1:nstep:end,2), zeros(size(f(1:nstep:end,1:nstep:end,1))),1,'w');
        title('Traction magnitude');
        hold off;
        %saveas(h_mag,['mag_',num2str(frame),'.tif'],'tiffn');
    end
        
    TFM_settings.poisson = s;
    TFM_settings.young = E;
    TFM_settings.micrometer_per_pix = pix_durch_my;
    TFM_settings.regularization_param = L;
    TFM_settings.meshsize = cluster_size;
    TFM_settings.zeropad = 'yes';
    TFM_settings.geldepth = depth;
    TFM_settings.crop_rim =cbnd;

   
    savefile_name = ['Reg-FTTC_results_finite_h_zeropad_',datestr(now, 'dd-mm-yy'),'.mat'];
    if exist(savefile_name)
        button = questdlg('The file exists already. Overwrite?','Error','Yes');
        if strcmpi(button,'No') || strcmpi(button,'')
                return;
        end
    end
    save(savefile_name,'TFM_results','TFM_settings','-mat');
end