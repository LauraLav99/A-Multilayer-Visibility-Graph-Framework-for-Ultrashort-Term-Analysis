clear; 
clc;
close all;
addpath('C:\Users\annad\PycharmProjects\MOONSHINE\MATLAB\subroutines')
% --- Impostazioni Percorsi ---
deskPath = 'C:\Users\annad\OneDrive - University of Pisa\Desktop';
saveRootFolder = 'RISULTATI_MOONSHINE';
esgosavefolder = fullfile(deskPath, saveRootFolder, 'ESGO_EDA_SMNA', "SURROGATES", "tables2");
csv_export_path =  fullfile(deskPath, saveRootFolder, 'ESGO_EDA_SMNA', "SURROGATES","CSV2"); % Dove salvare i file CSV per R
create_dir(csv_export_path);

phases = {'BODY_SCAN', 'REST'};
windows = {'60', '180'};
featureNames = {'AEO', 'I_tot', 'I_tot2', 'DA', 'L', 'Edd', 'Lambda', 'C_tot'};

fprintf('=== INIZIO ESPORTAZIONE UNIVERSALE SURROGATI IN CSV ===\n\n');

for p = 1:length(phases)
    curr_phase = phases{p};
    
    for w = 1:length(windows)
        curr_win = windows{w};
        
        % Lista di nomi file possibili da cercare (dal più recente al più vecchio)
        candidate_files = {
            sprintf('Surrogate_Detailed_Tracked_%s_%s.mat', curr_phase, curr_win),
            sprintf('Surrogate_NonHomologous_shuffled_%s_%s.mat', curr_phase, curr_win),
            sprintf('Surrogate_Balanced_shuffled_%s_%s.mat', curr_phase, curr_win),
            sprintf('MasterLibrary_Shuffled_%s_%s.mat', curr_phase, curr_win),
            sprintf('Surrogate_Balanced_%s_%s.mat', curr_phase, curr_win)
        };
        
        mat_path = '';
        for f = 1:length(candidate_files)
            test_path = fullfile(esgosavefolder, candidate_files{f});
            if exist(test_path, 'file')
                mat_path = test_path;
                mat_file = candidate_files{f};
                break;
            end
        end
        
        if isempty(mat_path)
            fprintf('[!] Nessun file .mat trovato per %s_%s. Salto.\n', curr_phase, curr_win);
            continue;
        end
        
        fprintf('Caricamento: %s ...\n', mat_file);
        data_loaded = load(mat_path, 'surrLibrary');
        surrLib = data_loaded.surrLibrary;
        
        tNames = fieldnames(surrLib);
        all_rows_table = table();
        
        for i = 1:length(tNames)
            subj_tbl = surrLib.(tNames{i});
            if isempty(subj_tbl), continue; end
            
            nRows = height(subj_tbl);
            colNames = subj_tbl.Properties.VariableNames;
            
            % -------------------------------------------------------------
            % COMPATIBILITÀ METADATI: Se mancano le colonne finali, le crea
            % -------------------------------------------------------------
            
            % 1. TraineeID
            if ~ismember('TraineeID', colNames)
                subj_tbl.TraineeID = repmat(string(tNames{i}), nRows, 1);
            end
            
            % 2. Session (per R)
            if ~ismember('Session', colNames)
                if ismember('SessionType', colNames)
                    subj_tbl.Session = string(subj_tbl.SessionType);
                else
                    subj_tbl.Session = repmat("First", nRows, 1);
                end
            end
            
            % 3. TraineeCond
            if ~ismember('TraineeCond', colNames)
                subj_tbl.TraineeCond = repmat(string(curr_phase), nRows, 1);
            end
            
            % 4. TrainerCond (nel caso omologo era uguale a TraineeCond)
            if ~ismember('TrainerCond', colNames)
                subj_tbl.TrainerCond = repmat(string(curr_phase), nRows, 1);
            end
            
            % 5. TrainerSession (nel caso omologo era uguale a SessionType)
            if ~ismember('TrainerSession', colNames)
                subj_tbl.TrainerSession = string(subj_tbl.Session);
            end
            
            % 6. PairCondition (es: "BODY_SCAN_vs_REST" o "BODY_SCAN_vs_BODY_SCAN")
            if ~ismember('PairCondition', colNames)
                subj_tbl.PairCondition = repmat(string(sprintf('%s_vs_%s', curr_phase, curr_phase)), nRows, 1);
            end
            
            % 7. Phase e Window globali
            subj_tbl.Phase = repmat(string(curr_phase), nRows, 1);
            subj_tbl.Window = repmat(string(curr_win), nRows, 1);
            
            % -------------------------------------------------------------
            % ORDINAMENTO RIGIDO DELLE COLONNE:
            % Colonne 1:5 -> Metadati Iniziali
            % Colonne 6:13 -> Le 8 Misure Fisse
            % Colonne 14+ -> Metadati Finali di Tracking
            % -------------------------------------------------------------
            meta_start = {'PseudoTrainer', 'TraineeDate', 'TrainerDate', 'SessionType', 'PairID'};
            meta_end   = {'TraineeCond', 'TrainerCond', 'TrainerSession', 'PairCondition', ...
                          'TraineeID', 'Session', 'Phase', 'Window'};
            
            orderedCols = [meta_start, featureNames, meta_end];
            subj_tbl = subj_tbl(:, orderedCols);
            
            all_rows_table = [all_rows_table; subj_tbl];
        end
        
        % Salvataggio del CSV unificato
        out_csv_name = sprintf('SurrLibrary_Detailed_%s_%s.csv', curr_phase, curr_win);
        out_csv_path = fullfile(csv_export_path, out_csv_name);
        
        writetable(all_rows_table, out_csv_path);
        fprintf('  -> Esportato: %s (%d righe totali)\n\n', out_csv_name, height(all_rows_table));
    end
end

fprintf('*** TUTTI I FILE CSV SONO STATI ESPORTATI E STANDARDIZZATI CON SUCCESSO ***\n');