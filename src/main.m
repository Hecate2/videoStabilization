%% Clear
clear
clc
close all

%% Read data
% ���� VideoReader ʵ����������Ƶ��תΪԪ����Ԫ����ÿ��Ԫ����һ֡��

%% Video stabilization
features = featureExtract(video);
M_cummulative = motionEstimator(features);
M_smooth = smooth(M_cummulative);

