function loc = findPeaks(metric,quality)
% ����ͼ�������׼�еľֲ����ֵ�� ����������һ���ż�
% ��ʾΪ�������ֵ��һ���֡�

maxMetric = max(metric(:));
if maxMetric <= eps(0)                  % 4.9407e-324
    loc = zeros(0,2, 'single');
else
    
    bw = imregionalmax(metric, 8);      % ���ض�����ͼ��BW�� BW ��ʶ�Ҷ�ͼ��I�е��������ֵ��������Сֵ�Ǿ��к㶨ǿ��ֵ�����ص��������,��Χ������ֵ�ϵ͵����ء�
    
    threshold = quality * maxMetric;    % Ĭ��Ϊ0.01
    bw(metric < threshold) = 0;
    bw = bwmorph(bw, 'shrink', Inf);    % ɾ���ڲ�������������״��������
    
    % �ų��߽��ϵĵ�
    bw(1, :) = 0;
    bw(end, :) = 0;
    bw(:, 1) = 0;
    bw(:, end) = 0;
    
    % �ҵ����λ��
    idx = find(bw);                     % ���ҷ���Ԫ�ص�������ֵ
    loc = zeros([length(idx) 2], 'like', metric );
    [loc(:, 2), loc(:, 1)] = ind2sub(size(metric), idx);
end