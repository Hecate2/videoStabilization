function [M_cummulative] = motionEstimator(feature)
%UNTITLED: estimate the cummulative motion between each pair of two 
%          adjacent frames.
%          Remember that your task is to estimate the shake in the video,
%          so be careful to exclude the true motion of the video (maybe 
%          this can be achieved by a high pass filter).
% Input:
%   feature: a cell whose every element is a feature vector of
%   corresponding frame.
% Output:
%   M_cummulativa: a cell containing the cummulative motion of each frame,
%   the i-th of which is the product of affine transform M_1, ..., M_i.
%   where M_i = [ S*cos��,-S*sin��,Tx;  
%                 S*sin��, S*cos��,Ty;
%                   0    ,   0    , 1 ]


end

