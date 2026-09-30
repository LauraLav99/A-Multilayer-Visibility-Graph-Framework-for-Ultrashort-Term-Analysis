% Calculate the VG and extarct the VG descriptors'
function analizzaSegnaliCoppie(save_path,fname, expDate, sessione, coppie_info, sensor_list, data_full, data_wb, data_w1, windows)
coppie = coppie_info.nomi;
coppie_struct = coppie_info.strutture;

num_coppie = length(coppie);
num_wb = size(data_wb, 2) - 1;
num_w1 = size(data_w1, 2) - 1;
% Preallocazione
flagent='noent';
switch flagent
    case 'noent'
Results_couple = cell(num_coppie, 11);
Results_couple_wb = cell(num_coppie * num_wb, 11);
Results_couple_w1 = cell(num_coppie * num_w1, 11);
    case 'ent'
%Entropia
Results_couple = cell(num_coppie,33);
Results_couple_wb = cell(num_coppie * num_wb, 33);
Results_couple_w1 = cell(num_coppie * num_w1, 33);
end
idx_wb = 1;
idx_w1 = 1;

for cc = 1:num_coppie
    coppia_name = coppie{cc};
    disp(coppia_name.Coppia)
    cz=coppie_struct{cc};
    % retrieve the sensor code to pair trainer and trainee singal

    [c_f_sensor, c_m_sensor] = get_sensore_coppia_sincro(coppia_name, selectCol(expDate, sessione));

    if contains(c_f_sensor, 'assente') || contains(c_m_sensor, 'assente'), continue; end

    s_id = sprintf('%s_%s_%s', coppie_struct{cc}, c_f_sensor, c_m_sensor);

    sensor_f_idx = find(strcmp(sensor_list, c_f_sensor));
    sensor_m_idx = find(strcmp(sensor_list, c_m_sensor));

    if isempty(sensor_f_idx) || isempty(sensor_m_idx), continue; end

    % 
    % 180s window signal-> wb  
    for wb = 1:num_wb
        rr_f_wb = data_wb{sensor_f_idx, wb + 1};
        rr_m_wb = data_wb{sensor_m_idx, wb + 1};
        window_name = windows{1}{wb};
        feats = extractMultiplexVGfeatures(rr_f_wb, rr_m_wb);
        Results_couple_wb(idx_wb, :) = format_results('couple', s_id, window_name, feats,flagent);
        idx_wb = idx_wb + 1;
    end

    % 60s window signal ->w1
    for w1 = 1:num_w1
        rr_f_w1 = data_w1{sensor_f_idx, w1 + 1};
        rr_m_w1 = data_w1{sensor_m_idx, w1 + 1};
        window_name = sprintf('%d_minuto', w1);
        feats = extractMultiplexVGfeatures(rr_f_w1, rr_m_w1);
        %feats = extractMultiplexVGfeatures_ENT(rr_f_w1, rr_m_w1,1);
        Results_couple_w1(idx_w1, :) = format_results('couple', s_id, window_name, feats,flagent);
        idx_w1 = idx_w1 + 1;
    end
end
if exist('feats','var')
fn=fieldnames(feats);
else
    fn='';
end

save(fullfile(save_path, fname), 'Results_couple', 'Results_couple_wb', 'Results_couple_w1','fn');
fprintf('Salvati risultati per analisi "couple".\n');
end

% Aggiungi questa piccola funzione helper in un altro file o in fondo
function result_row = format_results(coupling, s, start_w, feats, ent_flag)
switch ent_flag
    case 'noent'
        if strcmp(coupling, 'couple')
            result_row = {coupling, s, start_w, feats.AEO, feats.I_tot, feats.I_tot2, feats.DA, feats.L, feats.Edd, feats.Lambda, feats.C_tot};
        else % single o multi
            result_row = {coupling, s, start_w, NaN, NaN, NaN, feats.DA, feats.L, feats.Edd, feats.Lambda, feats.C_tot};
        end
    case 'ent'
        fn=fieldnames(feats);
        ret=cell(1,length(fn));
        for ll=1:length(fn)
            ret{1,ll}=feats.(fn{ll});
        end
        result_row=[{coupling, s, start_w},ret];

end
end