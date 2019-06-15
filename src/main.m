%% Clear
clear
clc
close all

%% Read data
% ���� VideoReader ʵ����������Ƶ��תΪԪ����Ԫ����ÿ��Ԫ����һ֡��
v = VideoReader('../data/01_input.avi');
video = {};
while hasFrame(v)
    video = [video, readFrame(v)];
end

%% Video stabilization
features = featureExtract(video);
M_cummulative = motionEstimator(features);
M_smooth = smooth_Kalman(M_cummulative);
% M_smooth = smooth_particle(M_cummulative);

% ��������ԭ����Ƶ��ÿ֡���д�������ÿ�����������չ��(x,y,1)���M_smooth^(-1)���õ�(x',y',1)

