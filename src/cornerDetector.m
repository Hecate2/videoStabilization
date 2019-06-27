function corners = cornerDetector(method, I, varargin)
% harrisMinEigen Compute corner metric
%   POINTS = harrisMinEigen('Harris',I) ���ؽǵ���Ľ��,
%   POINTS, ����һ������һ���Ҷ�ͼ��Ľǵ�λ�õ���Ϣ������Harris-Stephens algorithm.
%
%   POINTS = harrisMinEigen('MinEigen',I) ���ؽǵ���Ľ��,
%   POINTS, ����һ������һ���Ҷ�ͼ��Ľǵ�λ�õ���Ϣ, ������Shi and Tomasi�������С����ֵ���㷨
%
%   POINTS = harrisMinEigen(...,Name,Value) ����������������
%
%   'MinQuality'  ���� Q, 0 <= Q <= 1, ָ���ǵ���С�ɽ�����������Ϊͼ�������Ƕ���ֵ��һ���֡� 
%    �ϴ��Qֵ��������������Ľǵ㡣
%    Ĭ��ֵ: 0.01
%
%   'FilterSize'  ������S> = 3��ָ����˹�˲�������ƽ��ͼ��Ľ��䡣
%    �˲����ĳߴ�ΪS-by-S���˲����ı�׼ƫ��Ϊ��S / 3����
%    Ĭ��ֵ: 5
%
%   'ROI' ��ʽΪ[X Y WIDTH HEIGHT]��ʸ����ָ��һ�������������н���⵽���䡣
%    [X Y]�Ǹõ��������Ͻǡ�
%    Ĭ��ֵ: [1 1 size(I,2) size(I,1)]
%
% Class Support
% -------------
% ����ͼ��������߼��ģ�uint8��int16��uint16��single��
% double������������ʵ�ĺͷ��Ӵ�ġ�

%#codegen
%#ok<*EMCA>

% �ж������Ƿ���ȷ
if isSimMode()    
    try %#ok<EMTC>
        [params, filterSize] = parseInputs(I, varargin{:});    
    catch ME
        throwAsCaller(ME);
    end
else
    [params, filterSize] = parseInputs(I, varargin{:});
end

% ��ͼ��ת��Ϊsingle����.
I = im2single(I);


if params.usingROI   
    %����Ѷ���ROI�����ǻ���������չ���Ա������
    %��Ч���ض�����������ء� Ȼ�����ǲü�ͼ��
    %��չ�����ڵİٷֱȡ�
    imageSize   = size(I);
    expandSize  = floor(params.FilterSize / 2);
    expandedROI = expandROI(imageSize, ...
        params.ROI, expandSize);
    Ic = cropImage(I, expandedROI);    
else
    expandedROI = coder.nullcopy(zeros(1, 4, 'like', params.ROI));
    Ic = I;    
end

% ����һ����ά�ĸ�˹�˲���.
filter2D = createFilter(filterSize);
% ����Ƕ�������.
metricMatrix = cornerMetric(method, Ic, filter2D);
% �ڽǶ��������в��ҷ�ֵ�����ǵ�.
locations = findPeaks(metricMatrix, params.MinQuality);
locations = subPixelLocation(metricMatrix, locations);

% �ڹս�λ�ü���սǶ���ֵ��
metricValues = computeMetric(metricMatrix, locations);

if params.usingROI
    % ��Ϊt���ȱ���չ�ˣ����������Ҫ�ų�λ��I����ĵ�
    [locations, metricValues] = ...
        vision.internal.detector.excludePointsOutsideROI(...
        params.ROI, expandedROI, locations, metricValues);
end

% ����������һ���Ǽ��������棬�Է���������á�
corners = cornerPoints(locations, 'Metric', metricValues);

%==========================================================================
% ͨ��ʹ�ü���������λ�ô��ĽǶ���ֵ
% ˫���Բ�ֵ
function values = computeMetric(metric, loc)
sz = size(metric);

x = loc(:, 1);
y = loc(:, 2);
x1 = floor(x);
y1 = floor(y);
% ȷ�����е㶼��ͼ��߽���
x2 = min(x1 + 1, sz(2));
y2 = min(y1 + 1, sz(1));

values = metric(sub2ind(sz,y1,x1)) .* (x2-x) .* (y2-y) ...
         + metric(sub2ind(sz,y1,x2)) .* (x-x1) .* (y2-y) ...
         + metric(sub2ind(sz,y2,x1)) .* (x2-x) .* (y-y1) ...
         + metric(sub2ind(sz,y2,x2)) .* (x-x1) .* (y-y1);

%==========================================================================
% ����Ƕ�������
function metric = cornerMetric(method, I, filter2D)
% �����ݶ�
A = imfilter(I,[-1 0 1] ,'replicate','same','conv');
B = imfilter(I,[-1 0 1]','replicate','same','conv');

% ֻ��Ҫ��Ч�˲����֣���Ϊ�˲������ӳ١�
A = A(2:end-1,2:end-1);
B = B(2:end-1,2:end-1);

% ���� A, B, and C, ���ں�����������Ƕ�������
C = A .* B;
A = A .* A;
B = B .* B;

%  A, B, and C ������ά��˹�˲���
A = imfilter(A,filter2D,'replicate','full','conv');
B = imfilter(B,filter2D,'replicate','full','conv');
C = imfilter(C,filter2D,'replicate','full','conv');

% ����ͼ���С��ȥ���˲����ӳٵ�Ӱ��
removed = max(0, (size(filter2D,1)-1) / 2 - 1);
A = A(removed+1:end-removed,removed+1:end-removed);
B = B(removed+1:end-removed,removed+1:end-removed);
C = C(removed+1:end-removed,removed+1:end-removed);
% ���ѡ��Harris��ⷽ��
if strcmpi(method,'Harris')
    % Ĭ�ϣ�k = 0.04
    k = 0.04; 
    metric = (A .* B) - (C .^ 2) - k * ( A + B ) .^ 2;
else
    metric = ((A + B) - sqrt((A - B) .^ 2 + 4 * C .^ 2)) / 2;
end

%==========================================================================
% ����������λ��
function loc = subPixelLocation(metric, loc)
loc = subPixelLocationImpl(metric, reshape(loc', 2, 1, []));
loc = squeeze(loc)';% ����Ԫ���� A ��ͬ��ɾ�������е�һά�ȵ����� B����һά����ָ size(A,dim) = 1 ������ά�ȡ�

%==========================================================================
% ʹ��˫�������κ�����ϼ���������λ�á�
% Reference: http://en.wikipedia.org/wiki/Quadratic_function
function subPixelLoc = subPixelLocationImpl(metric, loc)

nLocs = size(loc,3);
patch = zeros([3, 3, nLocs], 'like', metric);
x = loc(1,1,:);
y = loc(2,1,:);
xm1 = x-1;
xp1 = x+1;
ym1 = y-1;
yp1 = y+1;
xsubs = [xm1, x, xp1;
         xm1, x, xp1;
         xm1, x, xp1];
ysubs = [ym1, ym1, ym1;
         y, y, y;
         yp1, yp1, yp1];
linind = sub2ind(size(metric), ysubs(:), xsubs(:));% ���±�ת��Ϊ��������
patch(:) = metric(linind);

dx2 = ( patch(1,1,:) - 2*patch(1,2,:) +   patch(1,3,:) ...
    + 2*patch(2,1,:) - 4*patch(2,2,:) + 2*patch(2,3,:) ...
    +   patch(3,1,:) - 2*patch(3,2,:) +   patch(3,3,:) ) / 8;

dy2 = ( ( patch(1,1,:) + 2*patch(1,2,:) + patch(1,3,:) )...
    - 2*( patch(2,1,:) + 2*patch(2,2,:) + patch(2,3,:) )...
    +   ( patch(3,1,:) + 2*patch(3,2,:) + patch(3,3,:) )) / 8;

dxy = ( + patch(1,1,:) - patch(1,3,:) ...
        - patch(3,1,:) + patch(3,3,:) ) / 4;

dx = ( - patch(1,1,:) - 2*patch(2,1,:) - patch(3,1,:)...
       + patch(1,3,:) + 2*patch(2,3,:) + patch(3,3,:) ) / 8;

dy = ( - patch(1,1,:) - 2*patch(1,2,:) - patch(1,3,:) ...
       + patch(3,1,:) + 2*patch(3,2,:) + patch(3,3,:) ) / 8;

detinv = 1 ./ (dx2.*dy2 - 0.25.*dxy.*dxy);

% �����ֵλ�ú�ֵ
x = -0.5 * (dy2.*dx - 0.5*dxy.*dy) .* detinv; % ���η��Xƫ��
y = -0.5 * (dx2.*dy - 0.5*dxy.*dx) .* detinv; % ���η��Yƫ��

% �������ƫ�ƶ�С��1�����أ���������λ��Ϊ
% ����Ϊ��Ч
isValid = (abs(x) < 1) & (abs(y) < 1);
x(~isValid) = 0;
y(~isValid) = 0;
subPixelLoc = [x; y] + loc;

%==========================================================================
% ����һ����˹�˲���
function f = createFilter(filterSize)
sigma = filterSize / 3;
f = fspecial('gaussian', filterSize, sigma);

%==========================================================================
function [params, filterSize] = parseInputs(I, varargin)

checkImage(I);

imageSize = size(I);

if isSimMode()    
    [params, filterSize] = parseInputs_sim(imageSize, varargin{:});    
else
    [params, filterSize] = parseInputs_cg(imageSize, varargin{:});
end

vision.internal.detector.checkMinQuality(params.MinQuality);
checkFilterSize(filterSize, imageSize);

%==========================================================================
function [params, filterSize] = parseInputs_sim(imgSize, varargin)

parser   = inputParser;
defaults = getParameterDefaults(imgSize);

parser.addParameter('MinQuality', defaults.MinQuality);
parser.addParameter('FilterSize', defaults.FilterSize);
parser.addParameter('ROI',        defaults.ROI);
parser.parse(varargin{:});

params = parser.Results;
filterSize = params.FilterSize;

params.usingROI = isempty(regexp([parser.UsingDefaults{:} ''],...
    'ROI','once'));

if params.usingROI
    vision.internal.detector.checkROI(params.ROI, imgSize);   
end

params.ROI = vision.internal.detector.roundAndCastToInt32(params.ROI);

%==========================================================================
function [params, filterSize] = parseInputs_cg(imgSize, varargin)

for n = 1 : numel(varargin)
    if isstring(varargin{n})
        coder.internal.errorIf(isstring(varargin{n}), ...
            'vision:validation:stringnotSupportedforCodegen');
    end
end

% varargin�����Ƿǿյġ�
defaultsNoVal = getDefaultParametersNoVal();
properties    = getEmlParserProperties();

[defaults, defaultFilterSize] = getParameterDefaults(imgSize);

optarg = eml_parse_parameter_inputs(defaultsNoVal, properties, varargin{:});

MinQuality = eml_get_parameter_value(optarg.MinQuality, ...
    defaults.MinQuality, varargin{:});

FilterSize = eml_get_parameter_value(optarg.FilterSize, ...
    defaultFilterSize, varargin{:});

ROI = eml_get_parameter_value(optarg.ROI, defaults.ROI, varargin{:});   

params.MinQuality = MinQuality;
%filterSize����struct'params'ʱ��ʧȥ���ĳ�����
%�����Filter Size�������ݵ�ԭ��
params.FilterSize = FilterSize; filterSize = FilterSize;

usingROI = ~(optarg.ROI==uint32(0));

if usingROI
    params.usingROI = true;  
    vision.internal.detector.checkROI(ROI, imgSize);   
else
    params.usingROI = false;
end

params.ROI = vision.internal.detector.roundAndCastToInt32(ROI);

%==========================================================================
%����û�û���趨filterSize��������ȡĬ��ֵ�ĺ���
function [filterSize] = getFilterSizeDefault()
filterSize = coder.internal.const(5);

%==========================================================================
%����û�û���趨��filterSize�Ĳ�����������ȡĬ��ֵ�ĺ���
function [defaults, filterSize] = getParameterDefaults(imgSize)
filterSize = getFilterSizeDefault();
defaults = struct('MinQuality' , single(0.01), ...     
                  'FilterSize' , filterSize,...
                  'ROI', int32([1 1 imgSize([2 1])]));

%==========================================================================
function properties = getEmlParserProperties()

properties = struct( ...
    'CaseSensitivity', false, ...
    'StructExpand',    true, ...
    'PartialMatching', false);

%==========================================================================
function defaultsNoVal = getDefaultParametersNoVal()

defaultsNoVal = struct(...
    'MinQuality', uint32(0), ... 
    'FilterSize', uint32(0), ... 
    'ROI',  uint32(0));

%==========================================================================
function r = checkImage(I)

vision.internal.inputValidation.validateImage(I, 'I', 'grayscale');

r = true;

%==========================================================================
function tf = checkFilterSize(x,imageSize)
coder.internal.prefer_const(x);

validateattributes(x,{'numeric'},...
    {'nonempty', 'nonnan', 'nonsparse', 'real', 'scalar', 'odd',...
    '>=', 3}, mfilename,'FilterSize');

% FilterSize must be a constant
coder.internal.assert(coder.internal.isConst(x), ...
    'vision:harrisMinEigen:filterSizeNotConst',...
    'IfNotConst','Fail');

% cross validate filter size and image size
maxSize = min(imageSize);
defaultFilterSize = getFilterSizeDefault();

coder.internal.errorIf(x > maxSize, ...
    'vision:harrisMinEigen:filterSizeGTImage',defaultFilterSize);

tf = true;

%==========================================================================
function flag = isSimMode()

flag = isempty(coder.target);
 