clear; close all; clc;
addpath('C:\Users\annad\PycharmProjects\MOONSHINE\MATLAB\subroutines')
% --- Settings ---
deskPath = 'C:\Users\annad\OneDrive - University of Pisa\Desktop'; % Set your path
sessioni = {'DATI_SESSIONE1','DATI_SESSIONE2','DATI_SESSIONE3'};
target_row = 19; % Change to 20 if you prefer the 60s segmentation
saveRootFolder='RISULTATI_MOONSHINE';

esgosavefolder=fullfile(deskPath,saveRootFolder,'ESGO_EDA_SMNA',"SURROGATES","tables");
create_dir(esgosavefolder)
if target_row==19
    suffix='180';
elseif target_row==20
    suffix='60';
end
filenamecat=strcat('Processed_Signals_for_Surrogates_',suffix,'.mat');
save_filename = fullfile(esgosavefolder,filenamecat);

% Initialize Cell Arrays with Headers
% Trainee: [Acronym, Group, SensorID, Session, Condition, Signals]
traineeCells = {'Acronym', 'Group', 'SensorID', 'Session', 'Condition', 'Signals'};
% Trainer: [Group, TrainerName, SensorID, Session, Condition, Signals]
trainerCells = {'Group', 'TrainerName', 'SensorID', 'Session', 'Condition', 'Signals'};

for ss = 1:length(sessioni)
    sessione = sessioni{ss};
    rootPath = fullfile(deskPath, sessione);

    % Determine Excel params and Trainer metadata
    if strcmp(sessione, 'DATI_SESSIONE2')
        trainerRow = 11;
        rangeExcel = [1 11];
        trainerName = 'CC';
        excelfile = "lista_coppie_sessione2.xlsx";
    else
        trainerRow = 17;
        rangeExcel = [1 17];
        trainerName = 'RC';
        if (ss == 1)
            excelfile =  "lista_coppie (1).xlsx";
        else
            excelfile="lista_coppia_3.xlsx";
        end
    end

    % Load Excel
    excelpath = fullfile(rootPath, excelfile);
    listacoppie = importfilecoppie(excelpath, "gruppi_sensori", rangeExcel);

    folders = switch_sessione(sessione);

    for ff = 1:length(folders)
        expDate = folders{ff};
        expDatePath = fullfile(rootPath, expDate);

        % Identify which Excel column contains the sensor IDs for this date
        targetCol = selectCol(expDate, sessione);

        % Locate ESGO folder
        flist = dir(expDatePath);
        foldercells = removedot(flist, 0);
        esgofolders = selectFolder(foldercells, 'ESGO_EDA_SMNA');
        if isempty(esgofolders), continue; end

        esgopath = fullfile(expDatePath, esgofolders);
        phases = removedot(dir(esgopath));

        for ll = 1:length(phases)
            phaseFolderName = phases{ll};
            mat_path = fullfile(esgopath, phaseFolderName, [phaseFolderName, '.mat']);
            if ~exist(mat_path, 'file'), continue; end

            % 1. Simplify Condition Name
            if contains(phaseFolderName, 'BODY', 'IgnoreCase', true)
                conditionLabel = 'BODY_SCAN';
            elseif contains(phaseFolderName, 'REST', 'IgnoreCase', true)
                conditionLabel = 'REST';
            else
                conditionLabel = phaseFolderName; % Fallback
            end

            % Load MAT data
            content = load(mat_path);
            data_cell = content.phase_cell_array;

            sensor_names_mat = data_cell(1, 2:end);
            raw_signals = data_cell(target_row, 2:end);

            % 2. Match each MAT sensor to an Excel Acronym
            for p = 1:length(sensor_names_mat)
                currSensorID = string(sensor_names_mat{p});
                allWindows = raw_signals{p}; % Saving all windows as requested

                % Find which row in the Excel (targetCol) matches this SensorID
                matchedRow = 0;
                for r = 1:height(listacoppie)
                    excelVal = string(listacoppie{r, targetCol});
                    if contains(excelVal, currSensorID, 'IgnoreCase', true)
                        matchedRow = r;
                        break;
                    end
                end

                if matchedRow > 0
                    % Get acronym from Column 2
                    acronymStr = string(listacoppie{matchedRow, 2});

                    % Check if this row is the Trainer row
                    if matchedRow == trainerRow
                        % Trainer: [Group, TrainerName, SensorID, Session, Condition, Signals]
                        newRow = {ss, trainerName, currSensorID, expDate, conditionLabel, allWindows};
                        trainerCells = [trainerCells; newRow];
                    else
                        % Trainee: [Acronym, Group, SensorID, Session, Condition, Signals]
                        newRow = {acronymStr, ss, currSensorID, expDate, conditionLabel, allWindows};
                        traineeCells = [traineeCells; newRow];
                    end
                else
                    fprintf('Warning: Sensor %s not found in Excel for date %s\n', currSensorID, expDate);
                end
            end
        end
    end
end

save('Surrogate_Tables_Final.mat', 'traineeCells', 'trainerCells');
disp('Tables generated successfully with acronyms and full windows.');



% Save the resulting cell arrays
save(save_filename, 'traineeCells', 'trainerCells');
fprintf('Success: trainerCells and traineeCells created.\n');

function singlefold=switch_sessione(sessione)
switch sessione
    case 'DATI_SESSIONE1'
        singlefold={'2310','3010','0611','1311','2011','2711','0412','1112','1812','1101'};
        %singlefold={'2310','1311','0611','1311','2011','2711','0412','1112','1812','1101'};
        %singlefold={'2310'};
        singlefold={'2310','1101'};
    case 'DATI_SESSIONE2'
        % singlefold={'1004','1704','2804','0805','1505','2205','0506','1206'};
        singlefold={'1004','1206'};
    case 'DATI_SESSIONE3'
        % singlefold={'301025','061125','131125','271125','041225','181225','181225_2'};
        %singlefold={'301025','061125','131125','271125','041225','181225'};
        singlefold={'301025','041225'};
end
end