function MPC = MeanPhaseCoherence(x,y)
% -------------------------------------------------------------------------
%This function computes the mean phase choerence for two signals.
% -------------------------------------------------------------------------
% Inputs:
%       x,y              	Signals to be analyzed. 
%                           x and y must be vector with the same length.
%   Outputs:
%       MPC                  Mean Phase Coherence value.
% -------------------------------------------------------------------------

    if  length(x) ~= length(y)
       error('The two input signal have different lengths')
    end
    N = length(x); 
    
    phi_x = unwrap(angle(x + j*hilbert(x))); %Instant phase from analytical signal
    phi_y = unwrap(angle(y + j*hilbert(y)));
    
    MPC = abs( (1/N)*sum(exp( j*(phi_x-phi_y) ))); %Ref. Lanata2016 

end