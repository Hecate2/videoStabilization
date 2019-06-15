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
% M_smooth = smooth_particle(M_cummulative, n);
% LPF

% ��������ԭ����Ƶ��ÿ֡���д�������ÿ�����������չ��(x,y,1)���M_smooth^(-1)���õ�(x',y',1)

%% test for Kalman filtering and LPF
M_test = cell(1,99);
y_test = ones(1,99);
y_noise = zeros(1,99);
for i = 1:99
    M_test{i} = sqrt(1/2) + 1e-2 * randn(3);
    y_noise(i) = sqrt(M_test{i}(1,1)^2 + M_test{i}(2,1)^2);
end

M_test_smooth = smooth_Kalman(M_test);

y_test_smooth = zeros(1,99);
for i = 2:100
    y_test_smooth(i-1) = sqrt(M_test_smooth{i}(1,1)^2 + M_test_smooth{i}(2,1)^2);
end
y_test_smooth = fft(y_test_smooth);
y_test_smooth(10:end) = 0;
y_test_smooth = real(ifft(y_test_smooth));

figure(1)
hold on
plot(1:99, y_noise, 'r')
plot(1:99, y_test, 'b')
plot(1:99, y_test_smooth, 'g')
legend('add noise', 'origin', 'Kalman filter')
