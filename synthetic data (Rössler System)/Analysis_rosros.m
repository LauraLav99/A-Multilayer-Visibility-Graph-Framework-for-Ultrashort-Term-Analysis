clc
clear all
close all
load('Dati_RosRos_rgn42.mat')

% _________________________________________________________________________
%% Setup Parameters
coupling_list = ["c_1","c_2","c_3","c_4"];
subjects = 1:30;
series_names = ["x1", "x2", "x3", "y1", "y2", "y3"]; % Name of the series in Data
bivariate_pairs = nchoosek(series_names, 2); %names of pairs to compute multilayer

% Path toolboxes
addpath('C:\Users\Utente\AppData\Roaming\MathWorks\MATLAB Add-Ons\Toolboxes\Fast natural visibility graph (NVG) for MATLAB\fast_NVG\fast_NVG')
addpath('C:\Users\Utente\Desktop\toolbox per MATLAB\funzioni MI\MutualInfo')

% _________________________________________________________________________
%% Analysis
Results = table(); row = 1;

for vg_test = [ "single","double", "multi_6"]
    which_vg = string(vg_test);

    for N = [30 60 120 240 480 600 720 900 1200 2400 3600] %window length
        start_w_tot = [1];  %Where to start in time serie (transient discarded in Create_RosRos_rgn42.m)  
        
        for c = 1:length(coupling_list) %couplinsg level
            coupling = coupling_list(c);
            
            for s = subjects %realizations
                
                % Load and cut to N all series
                s_data = struct();
                for sn = series_names
                    full_series = zscore(Data.RosRos.(coupling).(['s' num2str(s)]).(sn)); %normalization
                    s_data.(sn) = full_series(start_w_tot:start_w_tot+N-1); %cut
                end
                
                switch which_vg
                    case "single"
                        % Single gaph
                        for sn = series_names %loop on all series
                            ts = s_data.(sn);
                            VG = fast_NVG(ts, 1:length(ts), 'u', 0);
                            G = graph(VG);
                            feats = extractSingleVGfeatures(G);
                            
                            Results(row,:) = { ...
                                coupling, s, start_w_tot, which_vg, sn, N, ...
                                NaN,   feats.DA , NaN};
                            row = row + 1;
                        end
                        
                    case "double"
                        % Ciclo su tutte le 15 coppie bivariate possibili
                        for p = 1:size(bivariate_pairs, 1)
                            s1 = bivariate_pairs(p, 1);
                            s2 = bivariate_pairs(p, 2);
                            pair_label = strcat(s1, "_", s2);
                            
                            feats = extractMultiplexVGfeatures(s_data.(s1), s_data.(s2));
                             MPC = MeanPhaseCoherence(s_data.(s1), s_data.(s2));

                            Results(row,:) = { ...
                                coupling, s, start_w_tot, which_vg, pair_label, N, ...
                                feats.I_tot2,  feats.DA, MPC};
                            row = row + 1;
                        end
                        
                    case "multi_6"
                        % Multiplex (x1, x2, x3, y1, y2, y3)
                        VGs = cell(1, 6);
                        for k = 1:6
                            ts = s_data.(series_names(k));
                            VGs{k} = fast_NVG(ts, 1:length(ts), 'u', 0);
                        end
                        
                        I = eye(N);
                        M6 = cell(6, 6);
                        for r = 1:6
                            for col = 1:6
                                if r == col
                                    M6{r, col} = VGs{r};
                                else
                                    M6{r, col} = I;
                                end
                            end
                        end

                        G6 = graph(cell2mat(M6));
                        feats = extractSingleVGfeatures(G6);
                        
                       
                        Results(row,:) = { ...
                            coupling, s, start_w_tot, which_vg, "6_series", N, ...
                            NaN, feats.DA, NaN };
                        row = row + 1;
                end
                
            end % soggetti
        end % coupling
    end % N
end % vg_test

Results.Properties.VariableNames = [ ...
    "Coupling", "Subject", "StartW", "which_vg", "Series", "N", ...
     "I_tot2",   "DA", "MPC"];

writetable(Results, strcat("Results_ROSROS_window_VG_rgn42.xlsx"));