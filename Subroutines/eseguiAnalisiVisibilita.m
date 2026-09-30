% --- Nel file 'eseguiAnalisiVisibilita.m' ---

% CAMBIA la prima riga. Ora non restituisce più nulla.
function eseguiAnalisiVisibilita(phase_cell_array, save_path, expDate, sessione, coppie_info, coppie_infoTrainer)

% --- 1. Preparazione Dati (uguale a prima) ---
signals_full = phase_cell_array(14, 2:end);
signals_wb = phase_cell_array(19, 2:end);
signals_w1 = phase_cell_array(20, 2:end);
sensor_list = phase_cell_array(1, 2:end);
windows = phase_cell_array(3, 2:end);

num_sensors = length(sensor_list);
num_wb = length(signals_wb{1});
num_w1 = length(signals_w1{1});

v_wb = vertcat(signals_wb{:});
m_wb = [sensor_list', reshape(v_wb, num_sensors, num_wb)];

v_w1 = vertcat(signals_w1{:});
m_w1 = [sensor_list', reshape(v_w1, num_sensors, num_w1)];

size_coppie=size(coppie_info.nomi,2);
Tcoppie=table();
for ii=1: size_coppie
    t=coppie_info.nomi{1,ii};
    if isempty(Tcoppie)
        Tcoppie=t;
    else
        Tcoppie=vertcat(Tcoppie,t);
    end
end

% --- 2. Ciclo sui Tipi di Analisi ---
for vv = 1:length(visibility_cases)
    case_v = visibility_cases(vv);
    fprintf('\n--- Trainer trainee analysis: %s ---\n', case_v);

    fname="Results_coupleTrainer.mat";
    analizzaSegnaliCoppie(save_path, fname,expDate, sessione, coppie_infoTrainer, sensor_list, signals_full, m_wb, m_w1, windows);


end % end loop vvv
end % end function