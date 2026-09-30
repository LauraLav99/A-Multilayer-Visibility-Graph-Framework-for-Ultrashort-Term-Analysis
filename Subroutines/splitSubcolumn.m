function T=splitSubcolumn(T,file2load)
if contains(file2load,'couple')

    % --- 1. Ensure the 'Subject' column is a modern 'string' array ---
    % This makes text manipulation much easier and more robust.
    T.Subject = string(T.Subject);

    % --- 2. Find the position of the second underscore ---
    % strfind returns the indices of ALL occurrences of the delimiter.
    % We use cellfun to apply this to each string in the column.
    k = strfind(T.Subject, '_');
    % k will be a cell array like {[7, 9], [7, 9], [8, 10]}

    % Extract the index of the second occurrence for each row.
    % This will be our splitting point.
    split_indices = cellfun(@(x) x(2), k);
    % split_indices will be [9; 9; 10]

    % --- 3. Use extractBefore and extractAfter to create the new columns ---
    % 'extractBefore' gets everything before the specified index.
    new_col_Coppia = extractBefore(T.Subject, split_indices);

    % 'extractAfter' gets everything after the specified index.
    new_col_ID = extractAfter(T.Subject, split_indices);

    % --- 4. Add the new columns to the table ---
    % Use addvars to add the new columns to the original table.
    T = addvars(T, new_col_Coppia, new_col_ID, 'NewVariableNames', {'Coppia', 'ID'},'After',1);
    T=removevars(T,'Subject');
elseif contains(file2load,'single')
    % --- 1. Ensure the 'Subject' column is a modern 'string' array ---
    % This makes text manipulation much easier and more robust.
    % --- 3. Prealloca le nuove colonne per efficienza ---
    num_rows = height(T);
    Sensor = string(repmat("<missing>", num_rows, 1));
    Subjecti = string(repmat("<missing>", num_rows, 1));
    Coppia = string(repmat("<missing>", num_rows, 1));

    % --- 4. Ciclo For Robusto per Processare Ogni Riga ---
    for i = 1:num_rows
        current_string = T.Subject(i);

        % Dividi la stringa in base al delimitatore '|'
        parts = split(current_string, '|');

        % 'parts' è un cell array. Rimuoviamo eventuali celle vuote alla fine
        % che 'split' può creare se la stringa finisce con il delimitatore.
        if isempty(parts{end})
            parts(end) = [];
        end

        num_parts = length(parts);

        % Applica la logica in base al numero di parti trovate
        switch num_parts
            case 1
                % Caso: "A91D" (non c'è '|') o "no coppia"
                Sensor(i) = parts{1};
                % Subject e Coppia rimangono <missing>

            case 2
                % Caso: "a256|no coppia"
                Sensor(i) = parts{1};
                Subjecti(i) = parts{2}; % Il secondo elemento va in Subject
                % Coppia rimane <missing>

            case 3
                % Caso: "A91D|sub1|coppia_1"
                Sensor(i) = parts{1};
                Subjecti(i) = parts{2};
                Coppia(i) = parts{3};

            otherwise
                % Gestisce casi imprevisti (es. con più di 2 '|')
                warning('Riga %d ha un formato imprevisto: %s', i, current_string);
        end
    end

    % --- 5. Aggiungi le nuove colonne e pulisci la tabella ---
    T = addvars(T, Sensor, Subjecti, Coppia, 'After', 'Subject');
    T.Subject = []; % Rimuovi la colonna originale
    T=renamevars(T,'Subjecti','Subject');

end
end