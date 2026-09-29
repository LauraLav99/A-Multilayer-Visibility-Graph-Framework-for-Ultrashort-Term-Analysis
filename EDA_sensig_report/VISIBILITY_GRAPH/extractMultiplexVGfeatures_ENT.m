function feats = extractMultiplexVGfeatures_ENT(parent, child, do_comp)

    parent = parent(:);
    child = child(:);
    feats = struct();
    
    % ============================================================
    % Visibility graphs
    % ============================================================
    VG1 = fast_NVG(parent,1:length(parent),'u',0);
    VG2 = fast_NVG(child,1:length(child),'u',0);
    
    % multiplex graph
    G = graph([VG1 , eye(size(VG1)); ...
               eye(size(VG2)), VG2 ]);

    % ============================================================
    % Degree sequences
    % ============================================================
    d1 = zscore(degree(graph(VG1)));
    d2 = zscore(degree(graph(VG2)));
    dmulti = zscore(degree(G));


    % ============================================================
    % Embedding parameters
    % ============================================================
    [m1,tau1] = EmbDim(d1);
    [m2,tau2] = EmbDim(d2);
    [mm,tmm]  = EmbDim(dmulti);

    % ============================================================
    % Entropy features on degree sequences
    % ============================================================
    scl = 3;
    
    feats = addFeatures(feats, extractEntr(d1,scl,m1,tau1), "parent_deg_");
    feats = addFeatures(feats, extractEntr(d2,scl,m2,tau2), "child_deg_");
    feats = addFeatures(feats, extractEntr(dmulti,scl,mm,tmm), "multi_deg_");


    [feats.I_tot2_norm_deg,feats.I_tot2_lambda_deg] = MutualInfo(d1,d2);
    feats.xcorr_deg = xcorr(d1,d2,0,'normalized');
    % ============================================================
    % Multiplex coupling
    % ============================================================
    [~,~,~,feats.mci_tot_deg] = MCI_new2([d1,d2]',[m1 m2], 0.15,2,[tau1 tau2],scl);
    [feats.mdistAG_deg] = MDistEn([d1,d2]',[m1 m2]',[tau1 tau2]');

    % ============================================================
    % Optional: original signals
    % ============================================================
    if do_comp
    
        parent = zscore(parent);
        child  = zscore(child);
    
        [mp,taup] = EmbDim(parent);
        [mc,tauc] = EmbDim(child);
    
        feats = addFeatures(feats, extractEntr(parent,scl,mp,taup), "parent_orig_");
        feats = addFeatures(feats, extractEntr(child,scl,mc,tauc), "child_orig_");
    
        [~,~,~,feats.mci_tot_orig] = MCI_new2([parent,child]',[mp mc], 0.15,2,[taup tauc],scl);
        [feats.mdistAG_orig] = MDistEn([parent,child]',[mp mc]',[taup, tauc]');

        feats.xcorr_orig = xcorr(parent,child,0,'normalized');
        [feats.I_tot2_norm_orig,feats.I_tot2_lambda_orig] = MutualInfo(parent,child);
    
    end
   % feats = struct2table(feats);
end

  

function feats = addFeatures(feats, entr, prefix)

    names = fieldnames(entr);
    
    for i = 1:numel(names)
        feats.(prefix + names{i}) = entr.(names{i});
    end

end
function [m,tau] = EmbDim(sgn)
    % -- Optimal embedding dimension --
    perc = 0.2;
    tau = mdDelay(sgn,'criterion','localMin','maxLag', ...
                  round(perc * length(sgn)), 'plottype','none', ...
                   'numBins',min(256,length(unique(sgn))));
    
    [fnn, emb] = mdFnn(sgn, tau, 'doPlot',0,'maxEmb',10);
    idx_m = find(fnn < 10, 1);
    if isempty(idx_m); [~, idx_m] = min(fnn); end
    m = emb(idx_m);
    if m == 1, m = 2; end
end
function entr = extractEntr(sgn,scl,m,tau) % scl  = 3;

%      Sample entropy tolta su ordine di Mimma
%     entr.Samp_opt(1) = SampEn2(m, 0.15, sgn',tau);
%     [entr.MSamp_opt(1),~]    = multiscale_SampEn(sgn',scl,0.15,m,tau);

    entr.Fuzzy_opt(1) = fuzzyen_new(sgn', m, 0.15, 2, tau);
    [entr.MFuzzy_opt(1),~]    =  multiscale_fuzzyen(sgn', scl, 0.15, m, tau, 2);

    % Distribution Entropy ------------------------------------------------
    % number of point-distances
    N = length(sgn);
    
    % robust measure of spread via iqr
    width = iqr(sgn);
    % estimate bin width
    width = 2*width*N^(-1/3);
    
    % compute number of bins in base 2
    B = ceil(range(sgn)/width);
    B = 2^ceil(log2(B));
    %----------
    entr.Dist_opt(1) = disten(sgn, m, tau, B);
    [entr.MDist_opt(1),~]    = multiscale_DistEn(sgn,scl,B,m,tau);

end
