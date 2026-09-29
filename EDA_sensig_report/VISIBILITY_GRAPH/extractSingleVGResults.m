function Results_single=extractSingleVGResults(signal,s,start_w)
% --- Visibility graphs ---
VG1 = fast_NVG(signal, 1:length(signal), 'u', 0);


% --- Multiplex graph ---
G = graph(VG1 );
coupling="single";
feats = extractSingleVGfeatures(G);
Results_single = { ...
    coupling, s, start_w, ...
    NaN, NaN, NaN, ...
    feats.DA, feats.L, feats.Edd, ...
    feats.Lambda, feats.C_tot };
end