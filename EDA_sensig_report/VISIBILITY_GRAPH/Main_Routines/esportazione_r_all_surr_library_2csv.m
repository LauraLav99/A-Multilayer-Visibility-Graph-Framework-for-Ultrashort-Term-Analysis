%Routine to drop into csv the surrogates table created by the rotuine
%surrogates_shuffled.m 

clear; 
clc;
close all;
addpath('\subroutines')
% --- Setting Path
deskPath = '\Desktop';
saveRootFolder = 'RESULTS';
esgosavefolder = fullfile(deskPath, saveRootFolder, 'ESGO_EDA_SMNA', "SURROGATES", "tables2");
csv_export_path =  fullfile(deskPath, saveRootFolder, 'ESGO_EDA_SMNA', "SURROGATES","CSV2"); % Dove salvare i file CSV per R
create_dir(csv_export_path);

phases = {'BODY_SCAN', 'REST'};
windows = {'60', '180'};
featureNames = {'AEO', 'I_tot', 'I_tot2', 'DA', 'L', 'Edd', 'Lambda', 'C_tot'};

fprintf('=== CSV EXPORT ===\n\n');

for p = 1:length(phases)
    curr_phase = phases{p};
    
    for w = 1:length(windows)
        curr_win = windows{w};
        
        % Surrogates file list name
        candidate_files = {
            sprintf('Surrogate_Detailed_Tracked_%s_%s.mat', curr_phase, curr_win)};
        
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
            fprintf('[!] no file.\n', curr_phase, curr_win);
            continue;
        end
        
        fprintf('Loading: %s ...\n', mat_file);
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
            % create metadata columns if not present in the original file
            % 
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
            
            % 4. TrainerCond (Homologous condition )
            if ~ismember('TrainerCond', colNames)
                subj_tbl.TrainerCond = repmat(string(curr_phase), nRows, 1);
            end
            
            % 5. TrainerSession (homologous condition type)
            if ~ismember('TrainerSession', colNames)
                subj_tbl.TrainerSession = string(subj_tbl.Session);
            end
            
            % 6. PairCondition (es: "MEDITATION_vs_REST" o "MEDITATION_vs_BODY_SCAN")
            if ~ismember('PairCondition', colNames)
                subj_tbl.PairCondition = repmat(string(sprintf('%s_vs_%s', curr_phase, curr_phase)), nRows, 1);
            end
            
            % 7. Phase e Window globali
            subj_tbl.Phase = repmat(string(curr_phase), nRows, 1);
            subj_tbl.Window = repmat(string(curr_win), nRows, 1);
            
            % -------------------------------------------------------------
            % OOLUMNS OREDER:
            % Columns 1:5 -> Initial metadata
            % Columns 6:13 -> VG measure
            % Columns 14+ -> Tracking metadata
            % -------------------------------------------------------------
            meta_start = {'PseudoTrainer', 'TraineeDate', 'TrainerDate', 'SessionType', 'PairID'};
            meta_end   = {'TraineeCond', 'TrainerCond', 'TrainerSession', 'PairCondition', ...
                          'TraineeID', 'Session', 'Phase', 'Window'};
            
            orderedCols = [meta_start, featureNames, meta_end];
            subj_tbl = subj_tbl(:, orderedCols);
            
            all_rows_table = [all_rows_table; subj_tbl];
        end
        
        % CSV file saving
        out_csv_name = sprintf('SurrLibrary_Detailed_%s_%s.csv', curr_phase, curr_win);
        out_csv_path = fullfile(csv_export_path, out_csv_name);
        
        writetable(all_rows_table, out_csv_path);
        fprintf('  -> Esportato: %s (%d righe totali)\n\n', out_csv_name, height(all_rows_table));
    end
end

fprintf('*** TUTTI I FILE CSV SONO STATI ESPORTATI E STANDARDIZZATI CON SUCCESSO ***\n');