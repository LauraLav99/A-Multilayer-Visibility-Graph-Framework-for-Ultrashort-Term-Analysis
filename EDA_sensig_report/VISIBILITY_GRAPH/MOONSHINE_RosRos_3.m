clear all
close all
clc 

function singlefold=switch_sessione(sessione)
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
Results=cell(n_cell+1,11);
Results{1,1} = "Coupling";
Results{1,2} ='Subject';
Results{1,3}="start_with";
Results{1,4}="AEO";
Results{1,5}="I_tot";
Results{1,6}="I_tot2";
Results{1,7}="DA";
Results{1,8}="L";
Results{1,9}="Edd";
Results{1,10}="Lambda";
Results{1,11}="C_tot";
end


addpath('\fast_NVG')
addpath('\fast_HVG')
addpath('\sigstar')
addpath('\MutualInfo')
addpath('\subroutines')
addpath('\entropia')
addpath('\Mddisten')
addpath('\embedding')

% =========================================================================
% SCRIPT PRINCIPALE OTTIMIZZATO (Versione Corretta)
% =========================================================================

% --- Impostazioni ---
deskPath='C:\Users\annad\OneDrive - University of Pisa\Desktop';
saveRootFolder='RISULTATI_MOONSHINE';
esgosavefolder=fullfile(deskPath,saveRootFolder,'ESGO_EDA_SMNA');
create_dir(esgosavefolder)

% Aggiungi i percorsi alle tue funzioni helper
% addpath('percorso_alle_tue_funzioni');
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

    % --- Inizializzazione degli aggregatori di risultati ---
    Results_multi_body_wb_tot = initialize_Results(0);
    Results_multi_rest_wb_tot = initialize_Results(0);
    Results_multi_body_w1_tot = initialize_Results(0);
    Results_multi_rest_w1_tot = initialize_Results(0);
    Results_multi_body = initialize_Results(length(folders));
    Results_multi_rest = initialize_Results(length(folders));
    row_body = 2; row_rest = 2;
    
    disp(sessione);

    % --- Ciclo sulle date (esperimenti) ---
    for ff = 1:length(folders)
        expDate = folders{ff};
        fprintf('\n elaborazione di >> %s <<\n', expDate);
        expDatePath = fullfile(rootPath, expDate);
        
        folderlist = dir(expDatePath);
        foldercells = removedot(folderlist, 0);
        esgofolders = selectFolder(foldercells, 'ESGO_EDA_SMNA');
        if isempty(esgofolders), fprintf('Cartella ESGO non trovata per %s. Salto.\n', expDate); continue; end
        
        esgopath = fullfile(expDatePath, esgofolders);
        esgophases = dir(esgopath);
        esgophases = removedot(esgophases);

        % --- Ciclo sulle fasi (BODY_SCAN, REST_INIT) ---
        for ll = 1:length(esgophases)
            phase = esgophases{ll};
            fprintf('  -> Fase: %s\n', phase);
            
            file2load = strcat(phase, '.mat');
            mat_filepath = fullfile(esgopath, phase, file2load);
            if ~exist(mat_filepath, 'file'), fprintf('File .mat non trovato per %s. Salto.\n', phase); continue; end
            dati_caricati = load(mat_filepath);
            phase_cell_array = dati_caricati.phase_cell_array;
            
            esgophasesave = fullfile(sessionsavefolder, strcat(phase,'_NORMAL'));
            create_dir(esgophasesave);
            
            % --- ANALISI 'SINGLE' E 'COUPLE' (selezionate) ---
            % Queste analisi salvano i loro file in modo indipendente
            %visibility_cases_sc = ["single", "couple","coupleTrainer"];
             %visibility_cases_sc = ["coupleTrainer"];
             visibility_cases_sc = ["single"];
            %visibility_cases_sc = ["couple"];
             eseguiAnalisiVisibilita(phase_cell_array, esgophasesave, expDate, sessione, coppie_info, coppieTrainer_info,visibility_cases_sc);
            % 
            % % --- [NUOVA LOGICA] ANALISI 'MULTI' (gestita qui) ---
            % fprintf('\n--- Inizio analisi per caso: multi ---\n');
            % 
            % % Prepara i dati necessari per l'analisi 'multi'
            % signals_full = phase_cell_array(14, 2:end);
            % signals_wb = phase_cell_array(19, 2:end);
            % signals_w1 = phase_cell_array(20, 2:end);
            % sensor_list = phase_cell_array(1, 2:end);
            % windows = phase_cell_array(3, 2:end);
            % 
            % num_sensors = length(sensor_list);
            % num_wb = length(signals_wb{1});
            % num_w1 = length(signals_w1{1});
            % 
            % v_wb = vertcat(signals_wb{:});
            % m_wb = [sensor_list', reshape(v_wb, num_sensors, num_wb)];
            % v_w1 = vertcat(signals_w1{:});
            % m_w1 = [sensor_list', reshape(v_w1, num_sensors, num_w1)];
            % 
            % % Chiama la funzione specifica per l'analisi 'multi'
            % [res_multi_full, res_multi_wb, res_multi_w1] = analizzaSegnaliMulti(expDate, signals_full, m_wb, m_w1, windows);
            % 
            % % --- Aggregazione dei risultati (ora è sicura) ---
            % if contains(phase, "BODY_SCAN")
            %     if ~isempty(res_multi_full), Results_multi_body(row_body, :) = res_multi_full; row_body = row_body + 1; end
            %     if ~isempty(res_multi_wb), Results_multi_body_wb_tot = [Results_multi_body_wb_tot; res_multi_wb]; end
            %     if ~isempty(res_multi_w1), Results_multi_body_w1_tot = [Results_multi_body_w1_tot; res_multi_w1]; end
            % 
            % elseif contains(phase, "REST_INIT")
            %     if ~isempty(res_multi_full), Results_multi_rest(row_rest, :) = res_multi_full; row_rest = row_rest + 1; end
            %     if ~isempty(res_multi_wb), Results_multi_rest_wb_tot = [Results_multi_rest_wb_tot; res_multi_wb]; end
            %     if ~isempty(res_multi_w1), Results_multi_rest_w1_tot = [Results_multi_rest_w1_tot; res_multi_w1]; end
            % end
            % 
        end % Fine ciclo 'll' (fasi)
    end % Fine ciclo 'ff' (date)

    
    % --- Salvataggio finale dei risultati aggregati per la sessione ---
    % save(fullfile(sessionsavefolder, "Results_multi_TOTAL.mat"), ...
    %     'Results_multi_body', 'Results_multi_rest', ...
    %     'Results_multi_body_wb_tot', 'Results_multi_rest_wb_tot', ...
    %     'Results_multi_body_w1_tot', 'Results_multi_rest_w1_tot');
    % 
    fprintf('\nSalvati i risultati aggregati totali per la sessione %s.\n', sessione);
    
end % Fine ciclo 'ss' (sessioni)