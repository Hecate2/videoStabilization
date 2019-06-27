function expandedROI = expandROI(imageSize, originalROI, expandSize)
% expandROI����Ͷ�ʻر���
% expandedROI = expandROI��imageSize��originalROI��expandSize��
% ������չ��ROI��ͨ�����expandSize�Ĵ�С����չROI��ֱ������ͼ��߽硣
if isempty(originalROI)
    expandedROI = zeros(0,4,'like',originalROI);
else
    x1 = max(1, originalROI(:,1)-expandSize);
    y1 = max(1, originalROI(:,2)-expandSize);
    x2 = min(imageSize(2), originalROI(:,1)+originalROI(:,3)-1+expandSize);
    y2 = min(imageSize(1), originalROI(:,2)+originalROI(:,4)-1+expandSize);
    expandedROI = [x1, y1, x2-x1+1, y2-y1+1];
end