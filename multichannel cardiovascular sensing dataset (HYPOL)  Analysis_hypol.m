%% Characteristics of the study
% time[min] - time track expressed in minutes
% and synchronised beat-to-beat values of:
% 
% rri[ms] – duration of RR intervals in milliseconds;
% rr-flags[] – annotation about the beat type with codes 0 for the beat of sinus origin, 1 for ventricular depolarisation, 2 for supraventricular depolarisation, and 3 for technical artefact;
% rr-systolic[mmHg] – finger pressure SBP in mmHg;
% rr-diastolic[mmHg] – finger pressure DBP in mmHg;
% rr-mean[mmHg] – finger pressure MBP in mmHg;
% ibi[ms] – duration of inter-beat interval in ms.

clc
clear all
close all

addpath('C:\Users\Utente\AppData\Roaming\MathWorks\MATLAB Add-Ons\Toolboxes\Fast natural visibility graph (NVG) for MATLAB\fast_NVG\fast_NVG') %Toolbox NVG
addpath('C:\Users\Utente\Desktop\toolbox per MATLAB\funzioni MI\MutualInfo')
%  https://doi.org/10.1038/hr.2010.138 toglie extrasistole
fd = "Data\"; %path to save

%% Importa metadata e specifica opzioni analisi

%Load metadata-------------------------------------------------------------
meta = readtable("E:\HYPOL_FOR_SHARING\HYPOL clinical characteristics.xls");

%Import options for data
opts = delimitedTextImportOptions("NumVariables", 7); opts.DataLines = [2, Inf]; opts.Delimiter = "\t";
opts.VariableNames = ["time", "rr", "rrflags", "rrsystolic", "rrdiastolic", "rrmean", "ibi"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double"];
opts.ExtraColumnsRule = "ignore"; opts.EmptyLineRule = "read";

%Analysis parameters-------------------------------------------------------
max_t = 15*60;%[sec] window-length for the analysis

%Variable initialization---------------------------------------------------
Results = table();
row = 1;

%% Analysis
for n_subj = 1:height(meta)  %cycle on subjects

    subj_name = meta.fileName(n_subj); %name of the subject

    %data extraction ------------------------------------------------------
    data = readtable(["E:\HYPOL_FOR_SHARING\HYPOL RECORDINGS\" + subj_name],opts);
   
    % cutting--------------------------------------------------------------
    % Removal of first pat of signals in case of artifacts
    [~,tmp] = min(abs(data.time - max_t/60) );
    if n_subj == 198 
        data = data(50:tmp+50,:);
    elseif n_subj == 233
        data = data(500:tmp+500,:);
    elseif n_subj == 50
         data = data(1055:end,:);
    elseif n_subj == 47
        data = data(696:696+tmp,:);
    elseif n_subj == 243
         data = data(3:tmp,:);
     elseif n_subj == 268
         data = data(150:tmp,:); 
    else
        data = data(1:tmp,:);
    end

    %removal of exteme values if 0
    if data.rr(1,1) == 0 || data.rrmean(1,1) == 0 || data.rrdiastolic(1,1) == 0   || data.rrsystolic(1,1) == 0  
        data(1,:) = [];
    end
    
    if data.rr(end) == 0 || data.rrmean(end) == 0 || data.rrdiastolic(end) == 0   || data.rrsystolic(end) == 0  
        data(end,:) = [];
    end

    %removal of extra values hat are 0 ------------------------------------
    if n_subj == 44; data(1:2,:) =     []; end 
    if n_subj == 65; data(1:2,:) =     []; end
    if n_subj == 73;  data(1:3,:) =    []; end
    if n_subj == 85;  data(1:2,:) =    []; end
    if n_subj == 93;  data(1:7,:) =    []; end
    if n_subj == 150;  data(1,:) =     []; end
    if n_subj == 161;  data([1:3],:) = []; end
    if n_subj == 203;  data(1:2,:) =   []; end
    if n_subj == 241;  data(1:2,:) =   []; end
    if n_subj == 247;  data(1,:) =     []; end
    if n_subj == 46;  data(end,:) =    []; end

    

   %Removal of extreme values ---------------------------------------------
    idx = [data.rrflags ~= 0 | data.rr < 500 | data.rr > 1500 | ...
    data.rrsystolic < 10 | data.rrsystolic > 270 | data.rrmean < ...
    10 | data.rrmean > 270 |data.rrdiastolic < 10 | ...
    data.rrdiastolic > 270 ]'; %ufficiale
    idx = [[0 idx(1:end-1)] | idx | [idx(2:end) 0]]; %neighbour to stabilize spline
            
   %Interpolation to remove outliers --------------------------------------
   idx = [[0 idx(1:end-1)] | idx | [idx(2:end) 0]];
   idx(1) = 0; idx(end) = 0;
    
    data_clean = data;   
    for tt = ["rr","rrsystolic","rrdiastolic"]
        data_clean.(tt) = filloutliers(data.(tt),"pchip", "OutlierLocations",idx' );
    end

    % Conversion of time-axis in seconds
    data_final = data_clean;
    data_final.time = data.time*60; %time axis in seconds


    %loop over window length [sec]
    for N = [60 120 180  240   300   360   420   480   540   600   660   720   780   840  900] 
        max_rep = 1;
        for n_rep = 1:max_rep %how many repetitions for each window
            w_start = N*(n_rep-1) + data_final.time(1); %to avoid border effects
            w_end = N*(n_rep) + data_final.time(1);
            id_to_cut = data_final.time >= w_start & data_final.time <= w_end; %cut in time interval
            data_cut = data_final(id_to_cut,:);
            
            %% Analysis----------------------------------------------------
            
            for tt = ["rr","rrsystolic","rrdiastolic"]
    
               % --- Visibility graphs ---
                VG = fast_NVG(data_cut.(tt),data_cut.time, 'u', 0);
            
                % --- Multiplex graph ---
                G = graph(VG);
                try
                feats = extractSingleVGfeatures(G);
                catch
                    feats = table();
                    feats.DA = NaN; 
                end
                Results(row,:) = { ...
                    string(subj_name), string(tt),  N, n_rep,w_start,w_end, ...
                    NaN,   feats.DA };
                row = row + 1;
            end
    
            t_types = ["rr","rrsystolic","rrdiastolic"];
            matches = [1 2; 1 3; 2 3];
    
            for tt = 1:3
                parent = t_types(matches(tt,1));
                child = t_types(matches(tt,2));
                    
                try
                 feats = extractMultiplexVGfeatures(data_cut.(parent), data_cut.(child));
                catch
                    feats = table();
                    feats.I_tot2= NaN;
                    feats.DA = NaN;   
                end
                Results(row,:) = { ...
                    string(subj_name), strcat(parent,"_",child), N, n_rep,w_start,w_end, ...
                    feats.I_tot2,  feats.DA };
                row = row + 1;
            end
    
             % --- Visibility graphs for each child ---
            VG_rr = fast_NVG(data_cut.rr,data_cut.time,'u',0 );
            VG_rrsystolic = fast_NVG(data_cut.rrsystolic,data_cut.time,'u',0 );
            VG_rrdiastolic = fast_NVG(data_cut.rrdiastolic,data_cut.time,'u',0 );
            
            I = eye(size(VG_rr,1));
            
            % --- Multiplex graph (3 layers) ---
            G = graph([ VG_rr,   I,              I               ; ...
                        I,       VG_rrsystolic,  I               ; ...
                        I,       I,              VG_rrdiastolic  ]);
            try                
            feats = extractSingleVGfeatures(G);
            catch
                feats = table();
                feats.DA = NaN; 
            end
            Results(row,:) = { ...
               string(subj_name), "multi", N, n_rep,w_start,w_end, ...
                NaN,   feats.DA};
    
            row = row + 1;
        end
    end
end
Results.Properties.VariableNames = [ ...
    "Name","Type","N", "n_rep","w_start","w_end", ...
    "I_tot2","DA"];


writetable(Results,"HYPOL_noResample_windowLength.xlsx")

