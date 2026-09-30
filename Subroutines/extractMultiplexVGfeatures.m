function feats = extractMultiplexVGfeatures(parent, child)

    % --- Visibility graphs ---
    VG1 = fast_NVG(parent, 1:length(parent), 'u', 0);
    VG2 = fast_NVG(child,  1:length(child),  'u', 0);

    % --- Multiplex graph ---
    G = graph([VG1 , eye(size(VG1)); ...
               eye(size(VG2)), VG2 ]);

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

    feats.I_tot2 = MutualInfo(d1,d2);

    % ============================================================
    % Average Degree DA
    % ============================================================
    feats.DA = mean(degree(G));


end
