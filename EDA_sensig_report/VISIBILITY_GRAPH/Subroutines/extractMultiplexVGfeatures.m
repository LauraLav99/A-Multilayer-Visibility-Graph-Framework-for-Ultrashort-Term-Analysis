function feats = extractMultiplexVGfeatures(parent, child)

    % --- Visibility graphs ---
    VG1 = fast_NVG(parent, 1:length(parent), 'u', 0);
    VG2 = fast_NVG(child,  1:length(child),  'u', 0);

    % --- Multiplex graph ---
    G = graph([VG1 , eye(size(VG1)); ...
               eye(size(VG2)), VG2 ]);

    % ============================================================
    % Average Edge Overlap (AEO)
    % ============================================================
    w = 0; K = 0;
    for i = 1:height(VG1)
        for j = i:height(VG1)
            w = w + VG1(i,j) + VG2(i,j); 
            K = K + [VG1(i,j) | VG2(i,j)]; 
        end
    end
    w = w/2;
    feats.AEO = w/K;
    % [1] V. Nicosia, L. Lacasa, and V. Latora, "From multivariate time series to multiplex visibility graphs,” Aug. 2014
        
    % ============================================================
    % Inter-layer Mutual Information (degree)
    % ============================================================
    % Inter-Layer mutual information
    % [1] L. Lacasa, V. Nicosia, and V. Latora, "Network structure of multivariate time series,” Sci Rep, vol. 5, no. 1, p. 15508, Oct. 2015, doi: 10.1038/srep15508.
    % [2] R. Carmona-Cabezas, J. Gómez-Gómez, A. B. Ariza-Villaverde, E. Gutiérrez De Ravé, and F. J. Jiménez-Hornero, 2Multiplex Visibility Graphs as a complementary tool for describing the relation between ground level O3 and No2," Atmospheric Pollution Research, vol. 11, no. 1, pp. 205–212, Jan. 2020, doi: 10.1016/j.apr.2019.10.011.
    I_tot = 0;
    G1 = graph(VG1);
    G2 = graph(VG2);

    d1 = degree(G1);
    d2 = degree(G2);

    [h1] = histcounts(d1,'BinWidth',1,'BinMethod','integers');
    [h2] = histcounts(d2,'BinWidth',1,'BinMethod','integers');

    p1 = h1/numel(d1);
    p2 = h2/numel(d2);

    val1 = 1:length(h1);
    val2 = 1:length(h2);

    val1(h1==0) = []; p1(h1==0) = [];
    val2(h2==0) = []; p2(h2==0) = [];
try
    count = hist3([d1 d2],'ctrs',{val1 val2});
    p_joint = count/sum(count(:));

    for alpha = 1:length(val1) %ciclo su tutti i valori di G1
        for beta = 1:length(val2) %ciclo su tutti i valori di G2
            if  p_joint(alpha,beta) ~=0 %se il jointpdf è 0 salta, se no viene Inf o NaN
                I_tot = I_tot +  p_joint(alpha,beta)*(log(p_joint(alpha,beta)) -log(p1(alpha)) -log(p2(beta)) );
            end
        end
    end %fine calcolo I
catch ME
    warning('Failing computing I_tot');
end
    feats.I_tot  = I_tot;
    feats.I_tot2 = MutualInfo(d1,d2);

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
try
    % --- Power-law slope ---
    k = 1:length(pk);
    idx = pk>0 & k>=15 & k<=25;
    mdl = fitlm(log2(k(idx)),log2(pk(idx)));
    feats.Lambda = -mdl.Coefficients{end,1};
catch ME
    warning ("Lambda failing")
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
