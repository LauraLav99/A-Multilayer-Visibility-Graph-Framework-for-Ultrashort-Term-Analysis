function feats = extractSingleVGfeatures(G)


    % ============================================================
    % Network features (multiplex)
    % ============================================================
    feats.DA = mean(degree(G));

    L = distances(G,'method','unweighted');
    feats.L = sum(L.*~eye(size(L)),'all') / ...
              (numnodes(G)*(numnodes(G)-1));

    % --- Degree entropy ---
    h = histcounts(degree(G),'BinWidth',1);
    pk = h/height(G.Nodes);
    feats.Edd = -sum(pk.*log(pk),'omitnan');

    % --- Power-law slope ---
    try
    k = 1:length(pk);
    idx = pk>0 & k>=15 & k<=25;
    mdl = fitlm(log2(k(idx)),log2(pk(idx)));
    feats.Lambda = -mdl.Coefficients{end,1};
    catch ME
        warning("Lambda is failing")
        feats.Lambda=0;
    end
    % --- Clustering coefficient ---
    Ctot = 0;
    for v = 1:height(G.Nodes) %ciclo su tutti i nodi
        neigh = neighbors(G,v);
        if numel(neigh)<2, continue; end
        Cv = 0;
        for n = 1:length(neigh) 
            Cv = Cv + sum(ismember(neighbors(G,neigh(n)),neigh));
        end
        Ctot = Ctot + Cv/(numel(neigh)*(numel(neigh)-1));
    end
    feats.C_tot = Ctot/numnodes(G);

end
