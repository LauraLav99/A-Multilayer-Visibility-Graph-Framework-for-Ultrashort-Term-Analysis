function feats = extractSingleVGfeatures(G)


    % ============================================================
    % Network features (multiplex)
    % ============================================================
    feats.DA = mean(degree(G));


end
