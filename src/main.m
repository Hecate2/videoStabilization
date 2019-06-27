% project of video stabilization for CS:APP
% Group members: ���Һ���Ҷ���ϡ����������Ρ�������
%% Clear
clear
clc
close all

%% Read data
% ���� VideoReader ʵ����������Ƶ��תΪԪ����Ԫ����ÿ��Ԫ����һ֡��
v = VideoReader('../data/03_input.avi');
video = {};
while hasFrame(v)
    video = [video, readFrame(v)];
end

%% Video stabilization
[feature_i,feature_p] = featureExtract(video);
M_cummulative = motionEstimator(feature_i,feature_p);
M_smooth = smooth_Kalman(M_cummulative);
% % M_smooth = smooth_particle(M_cummulative, n);
% % LPF
% 
% % ��������ԭ����Ƶ��ÿ֡���д�������ÿ�����������չ��(x,y,1)���M_smooth^(-1)���õ�(x',y',1)
