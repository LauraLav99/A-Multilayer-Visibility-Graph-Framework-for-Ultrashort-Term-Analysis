function Results_single=extractSingleVGResults(signal,s,start_w)
% fast_NVG:Giovanni Iacobello (2026). Fast natural visibility graph (NVG) 
% for MATLAB (https://it.mathworks.com/matlabcentral/fileexchange/182737-fast-natural-visibility-graph-nvg-for-matlab),
% MATLAB Central File Exchange.
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