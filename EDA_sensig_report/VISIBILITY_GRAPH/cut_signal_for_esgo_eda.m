% cut signal for esgo
clear all
clc
close all
function sig_second=convert_from_string_to_s(sig_char)

sig_char_split=split(sig_char,":");
sig_second=str2double(sig_char_split{1})*3600+str2double(sig_char_split{2})*60+str2double(sig_char_split{3});


end

function phase_cell_array=initialize_cell_array(len_kbsubfold)
phase_cell_array=cell(12,len_kbsubfold+1);
pp=1;
phase_cell_array{1,pp}="sensorname";
phase_cell_array{2,pp}="phasica_originale";
phase_cell_array{3,pp}="windows by kubios";
phase_cell_array{4,pp}="[start_indx,end_indx]";
phase_cell_array{5,pp}="t_vect";
phase_cell_array{6,pp}="fs";
phase_cell_array{7,pp}="t_start_comune";
phase_cell_array{8,pp}="t_end_comune";
phase_cell_array{9,pp}="start_sig_second";
phase_cell_array{10,pp}="end_sig_second";
phase_cell_array{11,pp}="start_indx";
phase_cell_array{12,pp}="end_indx";
phase_cell_array{13,pp}="t_new";
phase_cell_array{14,pp}="phasica_interpolata";
phase_cell_array{15,pp}="t_old_cut";
phase_cell_array{16,pp}="rr";
phase_cell_array{17,pp}="start_reale";
phase_cell_array{18,pp}="end_reale";
phase_cell_array{19,pp}="rr_segmentato_kubios";
phase_cell_array{20,pp}="rr_segmentato_60s";

end


addpath('\MutualInfo')
addpath('\subroutines')


sessioni={'DATI_SESSIONE1','DATI_SESSIONE2','DATI_SESSIONE3'};
%sessioni={'DATI_SESSIONE1'};
fs=50;
for tt=1:length(sessioni)
    sessione=sessioni{tt};
    deskPath='';
    rootPath=fullfile(deskPath,sessione);
    switch sessione
        case 'DATI_SESSIONE1'
            singlefold={'231024','291024','061124','131124','201124','271124','041224','111224','181224','100125'};
            singlefold_exp={'2310','3010','0611','1311','2011','2711','0412','1112','1812','1101'};
            %singlefold={'2310','3010','1311','2711','1112','1101'};
            %singlefold={'3010'};
        case 'DATI_SESSIONE2'
            singlefold={'100425','170425','280425','080525','150525','220525','050625','120625'};
            singlefold_exp={'1004','1704','2804','0805','1505','2205','0506','1206'};
        case 'DATI_SESSIONE3'
            singlefold={'301025','061125','131125','271125','041225','181225'};
            singlefold_exp=singlefold;
    end
    for ll=1:length(singlefold)
        expDate=singlefold_exp{ll};
        expDatePath=fullfile(rootPath,expDate);
        folderlist=dir(expDatePath);
        foldercells=removedot(folderlist,0);
        % MatlabFolder=selectFolder(foldercells,'MATLAB');
        csvfolder='CSV_SMNA';
        CSVDaddypath=fullfile(rootPath,'CSV','EDA2',csvfolder);
        folly=singlefold{ll};
        csvfiles=dir(CSVDaddypath);
        csvfiles={csvfiles.name};
        csvdatefiles=selectFolder(csvfiles, folly);

        bodycsvfiles=selectFolder(csvdatefiles,'BODYSCAN');
        restfiles=selectFolder(csvdatefiles,'RESTINIT');

        matlabfiles=[bodycsvfiles;restfiles];


        KBFolder=selectFolder(foldercells,'_POST_KUBIOS');
        KBFolder_split=split(KBFolder,'/');
        KBFolder_split2=split( KBFolder_split,'_');
        KBFolder_split2=KBFolder_split2{1};


       esgosavefolder=fullfile(expDatePath,strcat(expDate,'_ESGO_EDA_SMNA'));

        if ~exist(esgosavefolder, 'dir')
            mkdir(esgosavefolder)
        end

        bodyfile2load=fullfile(CSVDaddypath,bodycsvfiles);
        restfile2load=fullfile(CSVDaddypath,restfiles);
        %expDate=bodycsvfiles{ii}(9:12);
        disp(expDate)
        % rfile=selectFolder(restfiles,expDate);
        
        bodytable=readtable(bodyfile2load,"ReadVariableNames",true,'VariableNamingRule','preserve');
        resttable=readtable(restfile2load,"ReadVariableNames",true,'VariableNamingRule','preserve');
        ced=cell(2,2);
        ced(1,1)={'BODY_SCAN'};
        ced(1,2)={'REST_INIT'};
        ced{2}=bodytable;
        ced{4}=resttable;
        ncol=selectCol(expDate,sessione);
        kbpath=fullfile(expDatePath,KBFolder);
        %list ppgfolder folders
        kbfolders=dir(kbpath);
        kbfolders=removedot(kbfolders,0);
        for ff=1:length(kbfolders)
            fold=kbfolders{ff};
            if ~(contains(fold,"REST_INIT") || contains(fold,"BODY_SCAN"))
                continue
            end
            phase=fold(12:end);
            phasepath=fullfile(kbpath,fold);
            kbsubfold=dir(phasepath);
            kbsubfold=removedot(kbsubfold);
            % cosa mi devo salvare? ilsensore,il segnale, windowslubios,index_cut, fs,t_vect
            phase_cell_array=initialize_cell_array(length(kbsubfold));

            phase_save_folder=fullfile(esgosavefolder,strcat(KBFolder_split2,'_',phase));
            if ~exist(phase_save_folder, 'dir')
                mkdir(phase_save_folder)
            end
            for pp=1:length(kbsubfold)
                sub=kbsubfold{pp};
                sub_split=split(sub,'_');
                sensorname=sub_split{2};
                selpath=fullfile(phasepath,kbsubfold{pp});
                infofilepath=fullfile(selpath, "inforun.json");
                struct_info=load_jsonfile(infofilepath);
                files=ced(1,:);
                table_index=find(contains(files,sub(17:end)));
                mt_table=ced{2,table_index};
                
                varnames=mt_table.Properties.VariableNames;
                mt=table2array(mt_table(:,contains(mt_table.Properties.VariableNames,sensorname)));


                windows=struct_info.Sample_limits__hhmmss_;
                [windows_sorted, start_sig_char, end_sig_char] = sortWindowsChronologically(struct_info.Sample_limits__hhmmss_);
                %devo ordinare le windows


                % Questi sono i tuoi t1 e t2 di interesse per questo segnale
                t1_interesse = convert_from_string_to_s(start_sig_char);
                t2_interesse = convert_from_string_to_s(end_sig_char);

                % --- Logica robusta per trovare i limiti REALI ---
                t_vect = 0:1/fs:(length(mt)-1)/fs;
                % Trova il PRIMO indice >= t1_interesse
                start_idx_reale = find(t_vect >= t1_interesse, 1, 'first');
                % Trova l'ULTIMO indice <= t2_interesse
                end_idx_reale = find(t_vect <= t2_interesse, 1, 'last');

                % Salva tutto nel cell array
                phase_cell_array{1, pp+1} = sensorname;
                phase_cell_array{3,pp+1}=windows_sorted;
                phase_cell_array{5, pp+1} = t_vect;
                phase_cell_array{6, pp+1} = fs;
                phase_cell_array{9, pp+1} = t1_interesse; % t1 di interesse
                phase_cell_array{10, pp+1} = t2_interesse; % t2 di interesse
                phase_cell_array{11, pp+1} = start_idx_reale;
                phase_cell_array{12, pp+1} = end_idx_reale;
                phase_cell_array{16, pp+1} = mt;% il segnale eda

                % Salva i tempi REALI di inizio e fine del segnale tagliato
                if ~isempty(start_idx_reale) && ~isempty(end_idx_reale) && start_idx_reale < end_idx_reale
                    phase_cell_array{17, pp+1} = t_vect(start_idx_reale);
                    phase_cell_array{18, pp+1} = t_vect(end_idx_reale);
                else
                    phase_cell_array{17, pp+1} = NaN; % Segna come invalido
                    phase_cell_array{18, pp+1} = NaN;
                end
            end

            % =========================================================================
            % FASE 2: CALCOLO DEL VETTORE TEMPORALE COMUNE E SICURO
            % =========================================================================
            fprintf('FASE 2: Calcolo del vettore temporale comune...\n');

            % Estrai tutti i tempi di inizio e fine reali
            start_reali = cell2mat(phase_cell_array(17, 2:end));
            end_reali = cell2mat(phase_cell_array(18, 2:end));

            % Calcola i limiti sicuri
            % L'inizio sicuro è l'ULTIMO tra tutti gli inizi reali
            t_start_comune = max(start_reali);
            % La fine sicura è la PRIMA tra tutte le fini reali
            t_end_comune = min(end_reali);

            % Applica la tua regola: se l'inizio è < 2s, forzalo a 2s
            if t_start_comune < 2
                t_start_comune = 2;
                fprintf('Inizio comune forzato a 2 secondi.\n');
            end

            % Controlla se l'intervallo risultante è valido
            if t_start_comune >= t_end_comune
                error('Errore fatale: non è stato trovato un intervallo temporale comune valido tra tutti i segnali.');
            end

            % Crea il nuovo vettore temporale
            fs_resample = 4; % 4 Hz
            t_new = t_start_comune : 1/fs_resample : t_end_comune;

            fprintf('Intervallo comune calcolato: da %.2f s a %.2f s. Creato t_new di %d punti.\n', ...
                t_start_comune, t_end_comune, length(t_new));

            % =========================================================================
            % FASE 3: INTERPOLAZIONE E SALVATAGGIO FINALE
            % =========================================================================
            fprintf('FASE 3: Esecuzione dell''interpolazione per ogni segnale...\n');

            for kk = 2:size(phase_cell_array, 2)
                t_old = phase_cell_array{5, kk};
                rr_old = phase_cell_array{16, kk};

                % Controlla se il segnale è valido
                if isempty(t_old) || isempty(rr_old)
                    rr_interpolato = NaN(size(t_new)); % Riempi di NaN se il segnale originale era vuoto
                else
                    % Esegui l'interpolazione. Non c'è bisogno di tagliare i vettori!
                    % interp1 è ottimizzato per gestire questo. La chiamata ora è sicura
                    % e non produrrà NaN ai bordi.
                    rr_interpolato = interp1(t_old, rr_old, t_new, 'linear'); % 'linear' è veloce e standard
                    %rr_interpolato=decimate(rr_old,12);
                end
                [segmented_rr_windows, ~] = segmentSignalByEventWindows(rr_interpolato, t_new, windows_sorted, @convert_from_string_to_s);
                sovrapposizione=0;% secondi
                lunghezza_finestra = 60; % secondi
                [segmented_rr_60s, segmented_t_60s] = segmentSignalByFixedWindows(rr_interpolato, t_new, lunghezza_finestra, sovrapposizione);



                % Salva i risultati finali nel cell array
                phase_cell_array{13, kk} = t_new;          % Vettore tempo comune
                phase_cell_array{14, kk} = rr_interpolato;
                phase_cell_array{15, kk} = t_old;% Segnale RR ricampionato
                phase_cell_array{7, kk} = t_start_comune;
                phase_cell_array{8, kk} = t_end_comune;
                phase_cell_array{19,kk}=segmented_rr_windows;
                phase_cell_array{20,kk}=segmented_rr_60s;


                % Salva altre info di debug se vuoi (opzionale)
                phase_cell_array{2, kk} = rr_old; % rr originale completo
                phase_cell_array{4, kk} = [phase_cell_array{11,kk}, phase_cell_array{12,kk}]; % indici di taglio
            end

            fprintf('Interpolazione completata.\n');

            % Salvataggio finale del file .mat
            save(fullfile(phase_save_folder, strcat(KBFolder_split2, '_', phase, '.mat')), "phase_cell_array");
            fprintf('File %s salvato con successo.\n', strcat(KBFolder_split2, '_', phase, '.mat'));
        end
    end
end