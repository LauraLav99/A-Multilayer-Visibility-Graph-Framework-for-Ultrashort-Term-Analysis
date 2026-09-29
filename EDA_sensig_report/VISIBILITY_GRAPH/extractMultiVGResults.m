function result_row = extractMultiVGResults(signals_to_process, coupling, s, start_w)
%extractMultiVGResults Esegue l'analisi VG multiplex e restituisce UNA SINGOLA riga di risultati.
%   Questa è una funzione "pura": prende dati in input e restituisce un risultato,
%   senza modificare variabili esterne.

    % Chiama la funzione per creare il grafo
    G = createMultiplexGraph(signals_to_process, true);
    
    % Controlla se il grafo è vuoto (robusto)
    if isempty(G)
        % Se il grafo è vuoto, crea una struct di feature con NaN
        feats = struct('DA', NaN, 'L', NaN, 'Edd', NaN, 'Lambda', NaN, 'C_tot', NaN);
        warning('Grafo vuoto creato per soggetto %s, finestra %s. Risultati impostati a NaN.', s, start_w);
    else
        % Altrimenti, calcola le feature normalmente
        feats = extractSingleVGfeatures(G);
    end
    
    % Usa la funzione helper per formattare la riga di output.
    % Assicurati che 'format_results' esista nel tuo path.
    result_row = format_results(coupling, s, start_w, feats);
end