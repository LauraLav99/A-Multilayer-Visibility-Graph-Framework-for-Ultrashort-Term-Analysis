function output_table = removeRowsByValues(input_table, column_name, values_to_remove)
%removeRowsByValues Rimuove le righe da una tabella in base ai valori in una colonna specifica.
%
%   output_table = removeRowsByValues(input_table, column_name, values_to_remove)
%
%   @param      input_table         La tabella di input da filtrare.
%   @param      column_name         Una stringa con il nome della colonna da controllare.
%   @param      values_to_remove    Un array di stringhe o un cell array con i
%                                   valori da cercare e rimuovere.
%
%   @retval     output_table        La tabella filtrata, senza le righe contenenti i valori specificati.

    % --- Controlli di Sicurezza ---
    if ~istable(input_table)
        error('Il primo argomento deve essere una tabella.');
    end
    if ~ismember(column_name, input_table.Properties.VariableNames)
        error('La colonna "%s" non esiste nella tabella.', column_name);
    end

    % --- Logica di Filtraggio ---
    
    % Estrai la colonna di interesse
    column_data = input_table.(column_name);
    
    % Crea una maschera logica: 'true' per le righe che contengono uno dei valori da rimuovere
    rows_to_remove_mask = ismember(column_data, values_to_remove);
    
    % Inverti la maschera per ottenere le righe da MANTENERE
    rows_to_keep_mask = ~rows_to_remove_mask;
    
    % Applica la maschera alla tabella per rimuovere le righe
    output_table = input_table(rows_to_keep_mask, :);
    
    % --- Feedback all'utente ---
    num_removed = sum(rows_to_remove_mask);
    if num_removed > 0
        fprintf('%d righe sono state rimosse dalla tabella.\n', num_removed);
    else
        fprintf('Nessuna riga corrispondeva ai valori specificati. Nessuna riga rimossa.\n');
    end
end