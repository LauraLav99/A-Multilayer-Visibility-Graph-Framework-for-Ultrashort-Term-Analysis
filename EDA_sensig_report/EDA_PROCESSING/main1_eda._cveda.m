clc
clear all
close all

addpath('\cvxEDA')

% Prende i filer raw degli shimmer, ricampiona, fa il preprocessing con cvsEDA e poi li salva in csv

% Opzioni per importare eda -----------------------------------------------
opts = delimitedTextImportOptions("NumVariables", 7);
% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ";";
% Opzioni per importare eda
opts = delimitedTextImportOptions("NumVariables", 7);
% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ";";
% Specify column names and types
opts.VariableNames = ["TimeStamp", "Var2", "EDA", "Var4", "Var5", "Var6", "Var7"];
opts.SelectedVariableNames = ["TimeStamp", "EDA"];
opts.VariableTypes = ["datetime", "string", "double", "string", "string", "string", "string"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Specify variable properties
opts = setvaropts(opts, ["Var2", "Var4", "Var5", "Var6", "Var7"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var2", "Var4", "Var5", "Var6", "Var7"], "EmptyFieldRule", "auto");
opts = setvaropts(opts, "TimeStamp", "InputFormat", "yyyy-MM-dd HH:mm:ss.SSS");

% Opzioni processing EDA --------------------------------------------------
fs = 50; % Frequenza a cui ricampionare
desk_path = "";
% save_folder = "C:\Users\annad\OneDrive - University of Pisa\Desktop\DATI_SESSIONE1\CSV\EDA2";
EDA_folder="CSV_EDA";TONIC_folder="CSV_TONIC"; PHASIC_folder="CSV_PHASIC";
SMNA_folder="CSV_SMNA";



sessioni={"DATI_SESSIONE1","DATI_SESSIONE2","DATI_SESSIONE3"};
for ss=1:length(sessioni)
    sessione=sessioni{ss};
    data_path=fullfile(desk_path,sessione);
    save_folder = fullfile(data_path,"CSV","EDA4");
    create_dir(fullfile(save_folder,EDA_folder));create_dir(fullfile(save_folder,TONIC_folder));
create_dir(fullfile(save_folder,PHASIC_folder));
create_dir(fullfile(save_folder,SMNA_folder));

% 1) estrai lista date acquisizioni
%cd(data_path)
% 2. Get all contents of the directory
all_entries = dir(data_path);
%=date_list(~ismember({date_list.name},{'.','..'}));
%idx = [date_list.isdir].'; all_names = {date_list.name}.';

% 3. Create a logical mask (an array of true/false) for entries that are directories
is_dir_mask = [all_entries.isdir];
all_names={all_entries.name};
% 5. Create a logical mask for names that match the 4-digit pattern.
%    - 'regexp' is applied to each name in the 'all_names' cell array.
%    - 'cellfun' applies the 'isempty' function to the results.
%    - '~' inverts the result, so we get 'true' for names that DO match.


is_4digit_mask = ~cellfun('isempty', regexp(all_names, '^(\d{4}|\d{6}|\d{6}_\d)$'));

% 6. Combine the masks to find entries that are BOTH directories AND match the pattern
final_mask = is_dir_mask & is_4digit_mask;
%date_list = name(idx); %così prende solo le cartelle
% 7. Use the final logical mask to select only the desired folder names
subfolder_names = all_names(final_mask);
% 2) ciclo per ogni data di acquisizione
for i = 1:length(subfolder_names)
    %cd(fullfile(data_path,date_list{i})) %entra nella cartella
    folderpath=fullfile(data_path,subfolder_names{i});
    % cerca cartella che finisce con '_SPLIT_DATA'
    matchingFolders = dir(fullfile(folderpath, '**', '*_SPLIT_DATA'));
    
    %crea path  ed entra dentro split data
    fullPaths = fullfile({matchingFolders.folder}, {matchingFolders.name});
    fullPaths = string(fullPaths);
    %cd(fullPaths);

    % Lista di acquisizioni dentro split data
    dir_list = dir(fullPaths); dir_list=dir_list(~ismember({dir_list.name},{'.','..'})); %lista di meditazioni fatte

    % Ciclo sulle acquisizioni
    for phase = 1:length(dir_list)
        phasepath=fullfile(fullPaths,dir_list(phase).name);
        %cd(fullfile(dir_list(phase).folder,dir_list(phase).name))

        % Prendi tutti i csv
        csvFiles = dir(fullfile(phasepath, '*.csv'));
        
        % crea path
        csvFilePaths = fullfile({csvFiles.folder}, {csvFiles.name});
        csvFilePaths = string(csvFilePaths);

        %  Pattern per trovare SHIMMER del soggetto
        pattern = 'Shimmer_(\w{4})_Calibrated'; % Look for "Shimmer_<4 characters>_Calibrated"
        
        eda_CSV = table;
        tonic_CSV = table;
        phasic_CSV = table;
        smna_CSV=table;

        for n_subj = 1:length(csvFilePaths)
            %Trova shimmer del soggetto
            match = regexp(csvFilePaths{n_subj}, pattern, 'tokens');
            subj_code = match{1}{1};

            eda_table = readtable(csvFilePaths{n_subj}, opts);

            %Se primo soggetto del groppo, crea asse del tempo per ricampionare 
            if n_subj ==1
                t_tot = eda_table.TimeStamp(end) - eda_table.TimeStamp(1);
                t_tot = seconds(t_tot);
                t_i = 0:1/fs:t_tot;
            end
        
          % 1.4 Converti timestamp
            t_vect = datevec(eda_table.TimeStamp);
            t_vect = t_vect(:,:)- t_vect(1,:); %meno inizio segnale
            t_vect = t_vect(:,6) + t_vect(:,5)*60 + t_vect(:,4)*60*60;
            t_vect = t_vect';

            eda = eda_table{:,2}'; 

            %Interpolazione a 50Hz-----------------------------------------
            interp_mode = "pchip";
            [eda] = interp1(t_vect, eda,t_i,interp_mode);
            eda = eda(:);

            %Preprocessing cvxeda -----------------------------------------
            %modifiche a paametri standard: alpha messo a 8-3 invece che 8e-4
            [r_eda, p_eda, t_eda, l_eda, d_eda, e_eda, obj_eda] = cvxEDA(zscore(eda), 1/fs,2, 0.7, 10, 8e-3, 1e-2, 'quadprog');
            
            %Mettere a zero tutte componenti di SMNA < 0.5 o 1-----------------
            p_eda(p_eda <1) = 0; 

            eda = r_eda+t_eda; %sum phasic + tonic

            eda_CSV.(subj_code) = eda;
            tonic_CSV.(subj_code) = t_eda;
            phasic_CSV.(subj_code) = r_eda;
            smna_CSV.(subj_code)=p_eda;
            
        end

  
        % Extract the date and activity part
        pattern = '(\d{4})-(\d{2})-(\d{2})_(.*)|(\d{4})-(\d{2})-(\d{3})_(.*)'; % Match "YYYY-MM-DD_ACTIVITY"
        match = regexp(dir_list(phase).name, pattern, 'tokens');
 
        % Extract day and month from the date
        day = match{1}{3}; % Third captured group (DD)
        month = match{1}{2}; % Second captured group (MM)
        year=match{1}{1};year=year(3:end); % Second captured group (MM)
        datePart = strcat(day, month,year);
        
        % Extract the activity and remove underscore (if any)
        activityPart = strrep(match{1}{4}, '_', ''); % Fourth captured group (activity)
        

        name_to_save = strcat(activityPart, datePart,".csv");     

        writetable(eda_CSV,fullfile(save_folder,"CSV_EDA",name_to_save))
        writetable(tonic_CSV,fullfile(save_folder,"CSV_TONIC",name_to_save))
        writetable(phasic_CSV,fullfile(save_folder,"CSV_PHASIC",name_to_save))
        writetable(smna_CSV,fullfile(save_folder,"CSV_SMNA",name_to_save))
        
    end

end
end
