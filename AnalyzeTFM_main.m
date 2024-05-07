function AnalyzeTFM_main()

%
fprintf("This analysis script provides entries of traction field \n" + ...
    "visualization and basic analysis.\n");
fprintf("IMPORTANT: This is specifically designed for the output of \n" + ...
    "TFM_main.m, and it will not work with other data. \n");
fprintf("Please make sure you have the output file of TFM_main.m ready.\n");
fprintf("Visulization consists of two types: magnitude and vector.\n" + ...
    "Please select one of them.");
fprintf("Basic analysis includes: mean, median, max, min, and \n" + ...
    "standard deviation of the traction magnitude within a given ROI.\n");
fprintf("Please follow the instructions in the command window to proceed.");


processing = true;
status = 'idle';



while processing

    switch status
        case 'idle'
            fprintf("Command line instructions: \n" + ...
                "findmaxmag -> find max traction magnitude within a given ROI\n" + ...
                "findavgmag -> find avg traction magnitude within a given ROI\n" + ...
                "findall -> find all basic analysis results (This is the Default Entry)\n" + ...
                "findvarmag -> find variance of traction magnitude within a given ROI\n" + ...
                "finenergy -> find strain energy in the entire region\n" + ...
                "exit(q) -> exit the program\n");
            prompt = 'Please choose which data you want to compare: ';
            userInput = input(prompt, 's');
            switch userInput
                case 'findmaxmag'
                    status = 'getMaxMagROI';
                case 'findavgmag'
                    status = 'getAvgMagROI';
                case 'findall' 
                    status = 'all';
                case ''
                    status = 'all';
                case 'findvarmag'
                    status = 'getVarMagROI';
                case 'finenergy'
                    status = 'getStrainEnergy';
                case 'q'
                    status = 'exit';
                otherwise
                    fprintf("Invalid input. Please try again.\n");
                    status = 'idle';
            end
            if ismember(status, {'getMaxMagROI','getAvgMagROI','getVarMagROI','getStrainEnergy','all'})
                % load data
                [traction_magnitude_selected,roi,energy,avg_energy_density,method,nframes,data_filename_pattern,attemptId] = findTractionMagnitudeROI();
                frameId = traction_magnitude_selected(:,1);
                traction_magnitude_roi = traction_magnitude_selected(:,2);
                x_roi = traction_magnitude_selected(:,3);
                y_roi = traction_magnitude_selected(:,4);
                if nframes > 1
                    fprintf("Multiple frames are detected. Please specify the frame number you want to analyze.\n");
                    userFrame = input("Enter a frame number (0 means all frames)",'s');
                    iframe = str2double(userFrame);
                else
                    iframe = 1;
                end
            end
        case 'getMaxMagROI'
            [max_mag_first,pos_max_first,frame_max_first] = getMaxMagROI();
            fprintf("The maximum traction magnitude in the ROI is \n" + ...
                "magnitude %f, position x %f, y %f, frame %d \n",max_mag_first,pos_max_first(1),...
                pos_max_first(2),frame_max_first);
            status = 'save';
        case 'getAvgMagROI'
            avg_mag = getAvgMagROI();
            fprintf("The average traction magnitude in the ROI is %f\n",avg_mag);
            status = 'save';
        case 'getStrainEnergy'
            [se,se_density] = getStrainEnergy();
            fprintf("The strain energy in the entire region is %f\n" + ...
                "The average energy density in the entire region is %f\n",se,se_density);
            status = 'save';
        case 'getVarMagROI'
            var_mag = getVarMagROI();
            fprintf("The variance of traction magnitude in the ROI is %f\n",var_mag);
            status = 'save';
        case 'all'
            [max_mag_first,pos_max_first,frame_max_first] = getMaxMagROI();
            avg_mag = getAvgMagROI();
            var_mag = getVarMagROI();
            [se,se_density] = getStrainEnergy();
            fprintf("The maximum traction magnitude in the ROI is \n" + ...
                "magnitude %f, position x %f, y %f, frame %d \n",max_mag_first,pos_max_first(1),...
                pos_max_first(2),frame_max_first);
            fprintf("The average traction magnitude in the ROI is %f\n",avg_mag);
            fprintf("The variance of traction magnitude in the ROI is %f\n",var_mag);
            fprintf("The strain energy in the entire region is %f\n" + ...
                "The average energy density in the entire region is %f\n",se,se_density);
            status = 'save';
        case 'save'
            issave = questdlg('Do you want to save the results?','Save Results','Yes','No','Yes');
            if strcmp(issave,'Yes')
                [savename,savepath] = uiputfile("*.txt","Save the results as a text file");
                if ~exist(fullfile(savepath,savename),'file')
                    fileID = fopen(fullfile(savepath,savename),'w');
                    fprintf(fileID,"Data filename, Maximum traction magnitude fnmax (Pa), fnmax position x (pix), fnmax position y (pix), fnmax frame," ...
                        + "average traction magnitude fnavg (Pa), variance of traction magnitude fnvar (Pa^2), strain energy (muJ), average strain energy density (muJ/pix^2)," ...
                        + "attemptId, TF method\n");
                    checkvarexistance();
                    j = attemptId;

                    fprintf(fileID,"%s, %f, %f, %f, %d, %f, %f, %f, %f ,%d, %s \n", ...
                        data_filename_pattern,max_mag_first,pos_max_first(1),pos_max_first(2),...
                        frame_max_first,avg_mag,var_mag,se,se_density,j,method);

                else
                    fileID = fopen(fullfile(savepath,savename),'a');
                    checkvarexistance();
                    j = attemptId;
                    fprintf(fileID,"%s, %f, %f, %f, %d, %f, %f, %f, %f ,%d, %s \n", ...
                        data_filename_pattern,max_mag_first,pos_max_first(1),pos_max_first(2),...
                        frame_max_first,avg_mag,var_mag,se,se_density,j,method);
                end

                fclose(fileID);
                status = 'idle';
            end



        case 'exit'
            close('all')
            processing = false;
    end

end




    function [max_mag_first,pos_max_first,frame_max_first] = getMaxMagROI()
        if iframe == 0
            [max_mag,ii] = max(traction_magnitude_roi);
            ii_first = ii(1);
            max_mag_first = max_mag(1);
            frame_max_first = frameId(ii_first);
            pos_max_first = [x_roi(ii_first),y_roi(ii_first)];
        else
            traction_magnitude_roi_iframe = traction_magnitude_roi(frameId == iframe);
            pos_roi_iframe = [x_roi(frameId == iframe),y_roi(frameId == iframe)];
            [max_mag,ii] = max(traction_magnitude_roi_iframe);
            max_mag_first = max_mag(1);
            ii_first = ii(1);
            frame_max_first = iframe;
            pos_max_first = pos_roi_iframe(ii_first,:);
        end
    end

    function avg_mag = getAvgMagROI()
        if iframe == 0
            avg_mag = mean(traction_magnitude_roi);
        else
            avg_mag = mean(traction_magnitude_roi(frameId == iframe));
        end
    end

    function var_mag = getVarMagROI()
        if iframe == 0
            var_mag = var(traction_magnitude_roi);
        else
            var_mag = var(traction_magnitude_roi(frameId == iframe));
        end
    end

    function [e,e_density] = getStrainEnergy()
        if iframe == 0
            e = mean(energy);
            e_density = mean(avg_energy_density);
            fprintf('All frames are considered, the values strain energy(density) from all frames are averaged.\n')
        else
            e = energy(iframe);
            e_density = avg_energy_density(iframe);
        end
    end

    function checkvarexistance()
        if ~exist("max_mag_first","var")
            max_mag_first = -1;
            pos_max_first = [-1,-1];
            frame_max_first = -1;
        end
        if ~exist("avg_mag","var")
            avg_mag = -1;
        end

        if ~exist("var_mag","var")
            var_mag = -1;
        end

        if ~exist("se","var") || ~exist("se_density","var")
            se = -1;
            se_density = -1;
        end

    end



end