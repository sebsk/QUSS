function [ C_f ] = EstimateFunctionalErrorCovariance( HistoricalStruct, ...
    EigenTolerance, C_d)
%EstimateFunctionalErrorCovariance Uses a Monte Carlo approach to compute
% error covariance
%
% For non-linear transformations, we need a way to transform the error
% covariance from the original domain to the functional domain.
% We empirically determine the error using a Monte Carlo approach, then
% estimate a covariance in the transformed domain.
%
% Inputs:
%   HistoricalStruct: Struct containing historical data
%   EigenTolerance: (float) Amount of variance used to select number of
%   eigenvalues to keep during FPCA
%   C_d: Error covariance in original domain
%
% Outputs:
%    C_f: Error covariance in functional domain
%
% Notes:
%   This assumes that the error in the functional domain is still a
%   zero-mean Gaussian. Need to verify by examining distribution of df_error
%
% References:
% Hermans, Thomas, et al. "The Prediction-Focused Approach: An opportunity for 
% hydrogeophysical data integration and interpretation." EGU General Assembly 
% Conference Abstracts. Vol. 19. 2017.
%
% Author: Lewis Li (lewisli@stanford.edu)
% Date: October 4th 2016

NumRealizations = size(HistoricalStruct.data,1);
NumTimeSteps = size(HistoricalStruct.data,2);
NumHistoricalResponses = size(HistoricalStruct.data,3);

% Perform dimension reduction
histPCA = ComputeHarmonicScores(HistoricalStruct,0);
[noiseless_scores, ~] = MixedPCA(histPCA,0,EigenTolerance);

df_error = zeros(size(noiseless_scores));


for i = 1:NumRealizations
     fprintf('Working on realization %d\n',i)
     NoisyStruct = HistoricalStruct;

     % For each realization, empirically add a noise error from N(0,C_d)
     NoisyStruct.data(i,:,:) = HistoricalStruct.data(i,:,:) + ...
         randn(1,NumTimeSteps,NumHistoricalResponses)*C_d;
     
     % Perform dimension reduction on noisy signal
     noisyPCA = ComputeHarmonicScores(NoisyStruct,0);
     [noisy_score, ~] = MixedPCA(noisyPCA,0,size(noiseless_scores,2));
     
     % Compute error in functional domain
     df_error(i,:) = noisy_score(i,:) - noiseless_scores(i,:);
end

% Compute empirical covariance of error in functional domain
 C_f = cov(df_error);

end

