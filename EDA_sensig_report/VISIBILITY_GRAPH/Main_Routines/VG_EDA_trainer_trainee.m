% This routine extracts the VG measures. It computes the duplex layer Trainer-Trainee. 
% The inputs are the .mat files containing
% the signal already divided into 60 s and 180 s windows.

clear all
close all
clc

function singlefold=switch_sessione(sessione)
% Each participant group's data are saved in a different folder, named after
% the data recording. Each group is associated with a different Excel file
% containing the couples and the sensors used for the recording.
switch sessione
    case 'DATI_SESSIONE1'
        singlefold={'2310','3010','0611','1311','2011','2711','0412','1112','1812','1101'};
        %singlefold={'2310','1311','0611','1311','2011','2711','0412','1112','1812','1101'};
        %singlefold={'2310'};
    case 'DATI_SESSIONE2'
        singlefold={'1004','1704','2804','0805','1505','2205','0506','1206'};
    case 'DATI_SESSIONE3'
        % singlefold={'301025','061125','131125','271125','041225','181225','181225_2'};
        singlefold={'301025','061125','131125','271125','041225','181225'};
end

end
function indx=get_sensor_indx(sensorarray,c_f_sensor)
idc=strfind(sensorarray,c_f_sensor);
mask_idc=~cellfun('isempty',idc);
indx=find(mask_idc);
end

function Results=initialize_Results(n_cell)
%The fucntion initialize the result struct
Results=cell(n_cell+1,11);
Results{1,1} = "Coupling";
Results{1,2} ='Subject';
Results{1,3}="start_with";
Results{1,4}="I_tot2";
Results{1,5}="DA";
end

%adding folder path containg the subroutines used to extract the VG
%descriptors
addpath('\fast_NVG')
addpath('\fast_HVG')
addpath('\sigstar')
addpath('\MutualInfo')
addpath('\subroutines')
addpath('\entropia')
addpath('\Mddisten')
addpath('\embedding')

% =========================================================================
%
% =========================================================================

% --- Settings ---
deskPath='';
saveRootFolder='RESULTS';
esgosavefolder=fullfile(deskPath,saveRootFolder,'ESGO_EDA_SMNA');
create_dir(esgosavefolder)


%
sessioni = {'DATI_SESSIONE1','DATI_SESSIONE2','DATI_SESSIONE3'};
%sessioni = {'DATI_SESSIONE2','DATI_SESSIONE3'};

for ss = 1:length(sessioni)
    sessione = sessioni{ss};
    rootPath = fullfile(deskPath, sessione);
    sessionsavefolder = fullfile(esgosavefolder, sessione);
    create_dir(sessionsavefolder);

    folders = switch_sessione(sessione);
    [~, coppie_struct, coppie] = switch_sessione_coppie(rootPath, sessione);
    [~, coppie_structTrainer, coppieTrainer] = switch_sessione_coppie_trainer(rootPath, sessione);
    coppie_info = struct('nomi', {coppie}, 'strutture', {coppie_struct});
    coppieTrainer_info = struct('nomi', {coppieTrainer}, 'strutture', {coppie_structTrainer});

    % --- Initialize results aggregator ---
    Results_multi_body_wb_tot = initialize_Results(0);
    Results_multi_rest_wb_tot = initialize_Results(0);
    Results_multi_body_w1_tot = initialize_Results(0);
    Results_multi_rest_w1_tot = initialize_Results(0);
    Results_multi_body = initialize_Results(length(folders));
    Results_multi_rest = initialize_Results(length(folders));
    row_body = 2; row_rest = 2;

    disp(sessione);

    % --- loop along the data acquisition---
    for ff = 1:length(folders)
        expDate = folders{ff};
        fprintf('\n elaboration >> %s <<\n', expDate);
        expDatePath = fullfile(rootPath, expDate);

        folderlist = dir(expDatePath);
        foldercells = removedot(folderlist, 0);
        esgofolders = selectFolder(foldercells, 'EDA_SMNA');
        if isempty(esgofolders), fprintf('Folder did not found %s. Salto.\n', expDate); continue; end

        esgopath = fullfile(expDatePath, esgofolders);
        esgophases = dir(esgopath);
        esgophases = removedot(esgophases);

        % --- loop along the condition, Meditation and Rest ---
        for ll = 1:length(esgophases)
            phase = esgophases{ll};
            fprintf('  -> Fase: %s\n', phase);

            file2load = strcat(phase, '.mat');
            mat_filepath = fullfile(esgopath, phase, file2load);
            if ~exist(mat_filepath, 'file'), fprintf('File .mat missing per %s break.\n', phase); continue; end
            dati_caricati = load(mat_filepath);
            phase_cell_array = dati_caricati.phase_cell_array;

            esgophasesave = fullfile(sessionsavefolder, strcat(phase,'_NORMAL'));
            create_dir(esgophasesave);

            % --- Trainer Trainee extraction ---

            eseguiAnalisiVisibilita(phase_cell_array, esgophasesave, expDate, sessione, coppie_info, coppieTrainer_info,visibility_cases_sc);
            %
        end % end loop'll' (conditions)
    end % end loop 'ff' (date)


    % --- Salvataggio finale dei risultati aggregati per la sessione ---
    save(fullfile(sessionsavefolder, "Results_multi_TOTAL.mat"), ...
        'Results_multi_body', 'Results_multi_rest', ...
        'Results_multi_body_wb_tot', 'Results_multi_rest_wb_tot', ...
        'Results_multi_body_w1_tot', 'Results_multi_rest_w1_tot');
    %
    fprintf('\nSalvati i risultati aggregati totali per la sessione %s.\n', sessione);

end % Fine ciclo 'ss' (sessioni)