%% should load analysis results first;

i = 1;

nfiles = size(TFManalysis,1);

while i <= nfiles
    folder = strtrim(TFManalysis.Folder(i));
    if(strcmp(folder,""))
        folder="/Users/jian/Work/local/TFM_2D_DC/Pool_Jian";
        TFManalysis.Folder(i) = folder;
    end
    filename = strcat(TFManalysis.DataFilename(i),"_TFM_output.mat");
    fullname = fullfile(folder,filename);
    load(fullname);
    stage=TFManalysis.InfectionStage(i);
    save(fullname,"stage",'-append');
    disp(strcat("Progress: ",num2str(i),"/",num2str(nfiles)));
    clearvars -except i nfiles TFManalysis
    i = i+1;
end