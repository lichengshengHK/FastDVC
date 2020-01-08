function FastDVC( Parameter )
clc
Parameter.File_V0 ='C:\Users\Administrator\Desktop\DVC_sample\r-0.4-0.5-0.6\V0.mat';
Parameter.File_V1 = 'C:\Users\Administrator\Desktop\DVC_sample\r-0.4-0.5-0.6\V1.mat';
Parameter.File_save = 'C:\Users\Administrator\Desktop\DVC_sample\r-0.4-0.5-0.6\';
Parameter.s = 10;  %�����뾶
Parameter.M = 20;  %���Ӱ뾶
Parameter.Linter = 8;  %������
Parameter.XYCutNum = 1;  % �ڴ�ϵ����>1���Ͳ�ֵ����ʱ�ڴ�Ҫ��
Parameter.cpu_num = 4;  %���м������
Parameter.IC_GN_tn = 10; %���IC-GN��������
Parameter.Sub = 2;  % Ԥ��ֵϵ��
Parameter.c1 = 1.5; %PSO�㷨����
Parameter.c2 = 1.5;
Parameter.maxgen = 100;
Parameter.sizepop = 20;

Parameter.Error = 1e-6; %�ȶ���ֵ
Parameter.Vmax = Parameter.Sub*floor(Parameter.s/2); %��������ٶ�
Parameter.Vmin = -Parameter.Sub*floor(Parameter.s/2);
Parameter.Vmaxhalf = round(Parameter.Vmax/2);
Parameter.Vminhalf = round(Parameter.Vmin/2);
Parameter.w_start = 0.9;
Parameter.w_end = 0.4;
Parameter = JacPre( Parameter ); %Ԥ�ȼ����Jac����

V0 = importdata( Parameter.File_V0 );
V1 = importdata( Parameter.File_V1 );

disp( 'Start DVC ...' );
disp( '��ȡ�ļ����' );

% �����������=======================
[n, m, l] = size(V0);
[n1, m1, l1] = size(V1);
if n ~=n1 || m ~= m1 || l ~= l1
    disp( 'The size of V0 and V1 is not the same!  Please check again!' );
    error( 'The size of V0 and V1 is not the same!  Please check again!' );
end

Parameter.max_v = max( V0(:) );
if Parameter.max_v > 260
    V0 = uint16( V0 );
    V1 = uint16( V1 );
else
    V0 = uint8( V0 );
    V1 = uint8( V1 );
end

% ��ȡ�����ͳ�ʼ��================================================
Parameter.Vsize = [n; m; l]; %�������ά��
V1 = BlkprocInterp3( V1, Parameter );  % ��ֵ
disp( '����Ԥ������ϣ���ʼ���㣡');

% ��main����
tic
Parameter = DVCPara(V0, V1, Parameter ); %�������

disp( [ 'END DVC: ', num2str(toc) ] );

Lsum = Parameter.M + 3;
Parameter.FiledRegion = [ Lsum, n-Lsum; Lsum, m-Lsum; Lsum, l-Lsum ]; %��¼��������
Parameter.Dx=Parameter.Dx/Parameter.Sub;
Parameter.Dy=Parameter.Dy/Parameter.Sub;
Parameter.Dz=Parameter.Dz/Parameter.Sub;
DVC.Dx = Parameter.Dx;
DVC.Dy = Parameter.Dy;
DVC.Dz = Parameter.Dz;
DVC.ZNCC = Parameter.ZNCC;
DVC.FiledRegion = Parameter.FiledRegion;
file_DD = [ Parameter.File_save, 'DVC.mat' ]; %������
save( file_DD, 'DVC', '-v7.3'); %���������
end

function V = BlkprocInterp3( V, Parameter )
% �ֿ���ٲ�ֵ�������ڴ�����======================
val = max( V(:) );
Sub = Parameter.Sub;
Cut = Parameter.XYCutNum;
if Sub > 1 %��Ҫ���в�ֵ
    [x, y, z] = size( V );
    Vi = []; %��ʼ������
    
    Lx = 1 : round(x/Cut) : x;    if Lx(end) ~= x;    Lx(end+1) = x;    end
    Ly = 1 : round(y/Cut) : y;    if Ly(end) ~= y;    Ly(end+1) = y;    end
    Lz = 1 : round(z/Cut) : z;    if Lz(end) ~= z;    Lz(end+1) = z;    end
    
    xmax = Lx(2) - Lx(1) + 1;
    ymax = Ly(2) - Ly(1) + 1;
    zmax = Lz(2) - Lz(1) + 1;
    for k = 2 : length( Lx ) - 1 %��¼���ߴ�
        dx = Lx(k+1) - Lx(k) + 1;
        if dx > xmax;    xmax = dx;    end
    end
    for k = 2 : length( Ly ) - 1 %��¼���ߴ�
        dy = Ly(k+1) - Ly(k) + 1;
        if dy > ymax;    ymax = dy;    end
    end
    for k = 2 : length( Lz ) - 1 %��¼���ߴ�
        dz = Lz(k+1) - Lz(k) + 1;
        if dz > zmax;    zmax = dz;    end
    end
    [X, Y, Z] = meshgrid( 1 : 1/Sub : xmax, 1 : 1/Sub : ymax, 1 : 1/Sub : zmax );
    X = single( X );    Y = single( Y );    Z = single( Z );
    
    for k = 1 : length( Lz ) - 1
        DLxy = [];
        for i = 1 : length( Lx ) - 1
            DLx = [];
            for j = 1 : length( Ly ) - 1
                x1 = Lx(i);    x2 = Lx(i+1);
                y1 = Ly(j);    y2 = Ly(j+1);
                z1 = Lz(k);    z2 = Lz(k+1);
                
                VV = V( x1 : x2, y1 : y2, z1 : z2 );
                [n, m, l] = size( VV );
                VV = single( interp3( permute(single(VV), [2,1,3]), X, Y, Z, 'spline' ) );
                VV = VV( 1 : length(1 : 1/Sub : m), 1 : length(1 : 1/Sub : n), 1 : length(1 : 1/Sub : l) ); %�޳�����Ĳ���
                
                if val > 260
                    VV = uint16( VV );
                else
                    VV = uint8( VV );
                end
                DLx = cat(1, DLx, VV );
                
            end
            DLxy = cat(2, DLxy, DLx );
        end
        Vi = cat( 3, Vi, DLxy ); %������
    end
    [x, y, z] = size( Vi );
    linx = 1 : x;    linx( 2*Lx(2:end-1)-1 ) = [];
    liny = 1 : y;    liny( 2*Ly(2:end-1)-1 ) = [];
    linz = 1 : z;    linz( 2*Lz(2:end-1)-1 ) = [];
    V = Vi( linx, liny, linz );    %ɾ������ص��Ĳ���
    V = permute(V, [2,1,3]);
else
    if val > 260
        V = uint16( V );
    else
        V = uint8( V );
    end
end
end

function Parameter = JacPre( Parameter )
% Ԥ�ȼ����J����
M = Parameter.M;
Sub = Parameter.Sub;
Parameter.JacPre = zeros( (2*M+1)^3, 12, 'int8');
for i = 1 : 2*M+1
    for j = 1 : 2*M+1
        for k = 1 : 2*M + 1
            dx = Sub*(i-1) - Sub*M;
            dy = Sub*(j-1) - Sub*M;
            dz = Sub*(k-1) - Sub*M;
            Parameter.JacPre(i + (j-1)*(2*M+1) + (k-1)*(2*M+1)^2, :) = ...
                [ 1, dx, dy, dz, 1, dx, dy, dz, 1, dx, dy, dz ];
        end
    end
end
end

function Parameter = DVCPara( V0, V1, Parameter )

[ Parameter.Dx, Parameter.Dy, Parameter.Dz, Parameter.ZNCC, ~ ] = DVCParaKey(V0, V1, Parameter );

Parameter.Dx( isnan( Parameter.ZNCC ) ) = 0; %��϶����
Parameter.Dx( isinf( Parameter.ZNCC ) ) = 0;

Parameter.Dy( isnan( Parameter.ZNCC ) ) = 0; %��϶����
Parameter.Dy( isinf( Parameter.ZNCC ) ) = 0;

Parameter.Dz( isnan( Parameter.ZNCC ) ) = 0; %��϶����
Parameter.Dz( isinf( Parameter.ZNCC ) ) = 0;

Parameter.ZNCC( isnan( Parameter.ZNCC ) ) = 0; %��϶����
Parameter.ZNCC( isinf( Parameter.ZNCC ) ) = 0;
end

function [Dx, Dy, Dz, ZNCC, BigStrain] = DVCParaKey(V0, V1, Parameter )

%������ʼ��=======================
[n, m, l] = size(V0); %��V0Ϊ�������
numM = ( (2*Parameter.M + 1)^3 ); %ƥ�������Ŀ��ĸ
M = Parameter.M;

Lsum = Parameter.M + 3;
Lx = [Lsum : Parameter.Linter : n-Lsum]';
Ly = [Lsum : Parameter.Linter : m-Lsum]';
Lz = [Lsum : Parameter.Linter : l-Lsum]';
Lx(end) = n-Lsum;
Ly(end) = m-Lsum;
Lz(end) = l-Lsum;

% Ϊ�˲��м��㣬����ȫ����
x_key = length( Lx );
y_key = length( Ly );
z_key = length( Lz );
Dx = zeros( x_key, y_key, z_key, 'single' );
Dy = Dx;
Dz = Dx;
ZNCC = Dx;
BigStrain = Dx;

% ���ó�������===============================
Pso.C_initial = zeros( Parameter.sizepop, 1, 'single');
Pso.R_c = rand( Parameter.sizepop * Parameter.maxgen, 6, 'single' ); %λ�ƺͱ��β�������12��
Pso.ads = [ -Parameter.Sub*Parameter.s : Parameter.Sub*Parameter.s ]'; %��������
Pso.s = Parameter.s;
Pso.M = Parameter.M;
[ Pso.n1, Pso.m1, Pso.l1 ] = size( V1 );
Pso.ff_line = ones(1, numM, 'single' ) / numM; %���ھ���˷����
Pso.Sub = Parameter.Sub;
Pso.sp = [0, 0, 0];
Pso.SP = [ 0, 0, 0;   %������19����
    1, 0, 0;  -1, 0, 0;
    0, 1, 0;   0, -1, 0;
    0, 0, 1;   0, 0, -1;
    1, 1, 0;  -1, -1, 0;    1, -1, 0;   -1, 1, 0;
    1, 0, 1;   -1, 0, -1;   1, 0, -1;   -1, 0,1;
    0, 1, 1;   0, -1, -1;   0, 1, -1;  0, -1, 1 ];
Pso.numSP = length(Pso.SP);
Pso.C = zeros( Pso.numSP, 1, 'single' ); %���ϵ��
Pso.result = zeros(Parameter.maxgen, 1, 'single'); %��¼�������
Pso.end_break_num = round( Parameter.maxgen / 4 ); %���������������ֵ����Ϊ1/4
Pso.pophalf = zeros( 3, 2, 'single' ); %��¼pop������

L = -Parameter.Sub*Parameter.M : Parameter.Sub : Parameter.Sub*Parameter.M; %���ξ���ģ��
[U, V, W] = meshgrid( L, L, L ); %�����������������
Pso.U = single( permute( U, [2, 1, 3] ) );
Pso.V = single( permute( V, [2, 1, 3] ) );
Pso.Ww = single( W );
Pso.Umax = max(Pso.U(:));
Pso.Vmax = max(Pso.V(:));
Pso.Wmax = max(Pso.Ww(:));    clear U V W
Pso.JacPre = Parameter.JacPre; %Ԥ�ȼ����Jac�Ӿ���
Pso.p = zeros(1, 12, 'single');
Pso.tn = Parameter.IC_GN_tn;
Pso.r = zeros( Pso.tn, 1, 'single');
Pso.tp = zeros( Pso.tn, 12, 'single');
Pso.W = zeros(4, 4, 'single' ); %��������
Pso.W(4, :) = single( [0, 0, 0, 1] );
Pso.dW = eye(4, 4, 'single' );

% ����������=================================
parfor  (k = 1 : z_key, Parameter.cpu_num)
    z = Lz( k );
    
    for i = 1 : x_key
        x = Lx( i );
        % PSO��ʷ�����ȼ���λ��
        xyz_pre = [0, 0, 0];
        pp = Pso.p; %���β���
        
        for j = 1 : y_key
            y = Ly( j );
            
            ppi = Pso;
            ppi.xf = x;
            ppi.yf = y;
            ppi.zf = z;
            ppi.xyz_pre = xyz_pre;
            ppi.zncc = 0; %����Ԥ�жϼ�����Χ
            ppi.p = pp;
            
            % ����ο�����=========================================
            f = single( V0(x-ppi.M : x+ppi.M, y-ppi.M : y+ppi.M, z-ppi.M : z+ppi.M) );
            ppi.ff = f - ppi.ff_line * f(:); %ת����������
            ppi.ff_sqrt = sqrt( ppi.ff(:)' * ppi.ff(:) ); %����ƽ����
            
            % ���������������ϵ����ֵ===============================
            %����λ��
            ppi.xg = x;
            ppi.yg = y;
            ppi.zg = z;
            [ubest, fitnesszbest, IndeX, FitnesS] = PSO( V1, Parameter, ppi );
            ppi.uvw = ppi.ads( ubest ); %����ת��
            ZNCC(i, j, k) = fitnesszbest;
            ppi.zncc = fitnesszbest;
            
            % ����������=========================================
            if   x-M-1 > 0 && x+M+1 < n && ...
                    y-M-1 > 0 && y+M+1 < m && ...
                    z-M-1 > 0 && z+M+1 < l  && ...
                    fitnesszbest < 0.7  % �����&�߽���
                BigStrain(i, j, k) = 1; %���Ϊ�����
                [sp, zncc, ~] = ICGN3D( V0, V1, ppi );
            else %С���μ���======================================
                fit = FitnesS > 0;
                ppi.IndeX = IndeX( fit );
                ppi.FitnesS = FitnesS( fit );
                [sp, zncc] = SubPixel( V1, ppi );
            end
            
            Dx(i, j, k) = ppi.uvw(1) + sp(1);
            Dy(i, j, k) = ppi.uvw(2) + sp(2);
            Dz(i, j, k) = ppi.uvw(3) + sp(3);
            ZNCC(i, j, k) = zncc;
            
            if zncc > 0.8 % ��ֹ����
                xyz_pre = round( [ ppi.uvw(1) + sp(1), ppi.uvw(2) + sp(2), ppi.uvw(3) + sp(3) ] ); %Ϊ��һ���ж���׼��
            else
                xyz_pre = [0, 0, 0];
            end
            
        end
    end
end
end

function [zbest, fitnesszbest, IndeX, FitnesS] = PSO( V1, Parameter, ppi )
% ��������Ⱥ�㷨�Ż��������ֵ
%IndeX, FitnesS�ֱ��Ǽ�¼C�ľ���������ֵ��Cֵ
s = Parameter.Sub * Parameter.s;
popmax = 2*s + 1; %����ֵ��Χ
popmin = 1;

% ��Ԥ��ppi.xyz_pred�Ĳ�಻����һ��ԭ
pophalf = ppi.pophalf; %��¼������
if ppi.zncc > 0.7 && ppi.zncc < 1%��CNZZ���Լ�С, zncc>=1һ���Ǽ������
    phalf = 2 + abs( ( s/5 - 2 ) / 0.3 ) * ( ppi.zncc - 0.7 );
else
    phalf = 1;
end
s_half = s/phalf; %���
if s_half < 5;    s_half = 5;    end %������С������Χ
Parameter.Vmaxhalf = round( s_half / 2); %�޶���������ٶ�
Parameter.Vminhalf = -Parameter.Vmaxhalf;
ppi.xyz_pre = ppi.xyz_pre + s + 1;
pophalf(:, 1) = ppi.xyz_pre(1, :)' + s_half; %��ط�Χ
pophalf(:, 2) = ppi.xyz_pre(1, :)' - s_half;
pophalf = round( pophalf );
pophalf( pophalf > popmax ) = popmax;
pophalf( pophalf < popmin ) = popmin;

%��Ⱥ��ʼ��=================================
pop_rand = rand( Parameter.sizepop, 3); %��ʼ������λ��
pop = pop_rand;
if ppi.zncc > 0.7 && ppi.zncc < 1
    pop(:, 1) = round( pop_rand(:, 1) * 2 * s_half + pophalf(1, 2) );
    pop(:, 2) = round( pop_rand(:, 2) * 2 * s_half + pophalf(2, 2) );
    pop(:, 3) = round( pop_rand(:, 3) * 2 * s_half + pophalf(3, 2) );
else
    pop = round( pop_rand * popmax );
end

if length(ppi.xyz_pre(:, 1)) == 1
    pop(1, :) = ppi.xyz_pre; %����ת��
else
    pop(1:2, :) =ppi.xyz_pre; %����ת��
end

if rand > 1 - ppi.zncc  && ppi.zncc < 1%���ݵ�ǰԤ��ɿ��ԣ�����������Ĳ��
    pop( pop(:, 1) > pophalf(1, 1), 1 ) = pophalf(1, 1); %��С������Χ
    pop( pop(:, 1) < pophalf(1, 2), 1 ) = pophalf(1, 2);
    pop( pop(:, 2) > pophalf(2, 1), 2 ) = pophalf(2, 1); %��С������Χ
    pop( pop(:, 2) < pophalf(2, 2), 2 ) = pophalf(2, 2);
    pop( pop(:, 3) > pophalf(3, 1), 3 ) = pophalf(3, 1); %��С������Χ
    pop( pop(:, 3) < pophalf(3, 2), 3 ) = pophalf(3, 2);
else
    pop( pop < popmin ) = popmin;
    pop( pop > popmax ) = popmax;
end
C_initial = ppi.C_initial;
IndeX = []; %��¼C����ľ����������ֵ
FitnesS = [];

V = round( Parameter.Vmax * ( rand( Parameter.sizepop, 3) - 0.5 ) ); %��ʼ�������ٶ�
if rand > 1 - ppi.zncc && ppi.zncc < 1
    V( V > Parameter.Vmaxhalf ) = Parameter.Vmaxhalf;
    V( V < Parameter.Vminhalf ) = Parameter.Vminhalf;
else
    V( V > Parameter.Vmax ) = Parameter.Vmax;
    V( V < Parameter.Vmin ) = Parameter.Vmin;
end

[fitness, index] = CC(V1, ppi, pop, C_initial, IndeX, Parameter.sizepop ); %�������ӳ�ʼ����Ӧֵ
IndeX = cat(1, IndeX, index( fitness ~= 0 ) ); %��ϼ�¼
FitnesS = cat(1, FitnesS, fitness( fitness ~= 0 ) );

%Ѱ�ҳ�ʼ����ֵ
[bestfitness, bestindex] = max( fitness );
zbest = pop( bestindex, :); %��Ⱥ��ֵλ��
gbest = pop; %���弫ֵλ��
fitnessgbest = fitness; %���弫ֵ��Ӧֵ
fitnesszbest = bestfitness; %Ⱥ�弫ֵ��Ӧֵ

%����Ѱ������ֵ
result = ppi.result; %��¼�������
result(1) = 1;
end_break = 1; %��¼��������������
end_break_num = ppi.end_break_num; %���������������ֵ����Ϊ1/4

%Ԥ�����������
R_c = ppi.R_c;

for i = 1 : Parameter.maxgen
    w = Parameter.w_start -  (Parameter.w_start - Parameter.w_end) * (i/Parameter.maxgen)^2; %����Ȩ�ظ���
    %����λ�ú��ٶȸ���
    V = round( w * V + ...
        Parameter.c1 * R_c( (i-1)*Parameter.sizepop+1 : i*Parameter.sizepop, 1:3 ) .* ( gbest - pop ) ...
        + Parameter.c2 * R_c( (i-1)*Parameter.sizepop+1 : i*Parameter.sizepop, 4:6 ) .* ( [zbest(1) - pop(:,1), zbest(2) - pop(:,2), zbest(3) - pop(:,3) ] ) ); %�ٶȸ���
    
    if rand > 1 - ppi.zncc && ppi.zncc < 1
        V( V > Parameter.Vmaxhalf ) = Parameter.Vmaxhalf;
        V( V < Parameter.Vminhalf ) = Parameter.Vminhalf;
    else
        V( V > Parameter.Vmax ) = Parameter.Vmax;
        V( V < Parameter.Vmin ) = Parameter.Vmin;
    end
    pop = pop + V; %���Ӹ���
    
    % ��end_break > 1/2 ʱ����Сpop��zbest֮��Ĳ���
    % ���㼯���ڸ�����
    if end_break > end_break_num/2
        if end_break > 0.7*end_break_num
            pop( pop(:,1) > zbest(1) + 1, 1) = zbest(1) + 1;
            pop( pop(:,1) < zbest(1) - 1, 1) = zbest(1) - 1;
            
            pop( pop(:,2) > zbest(2) + 1, 2) = zbest(2) + 1;
            pop( pop(:,2) < zbest(2) - 1, 2) = zbest(2) - 1;
            
            pop( pop(:,3) > zbest(3) + 1, 3) = zbest(3) + 1;
            pop( pop(:,3) < zbest(3) - 1, 3) = zbest(3) - 1;
        else
            pop( pop(:,1) > zbest(1) + 2, 1) = zbest(1) + 2;
            pop( pop(:,1) < zbest(1) - 2, 1) = zbest(1) - 2;
            
            pop( pop(:,2) > zbest(2) + 2, 2) = zbest(2) + 2;
            pop( pop(:,2) < zbest(2) - 2, 2) = zbest(2) - 2;
            
            pop( pop(:,3) > zbest(3) + 2, 3) = zbest(3) + 2;
            pop( pop(:,3) < zbest(3) - 2, 3) = zbest(3) - 2;
        end
    end
    
    if rand > 1 - ppi.zncc && ppi.zncc < 1    %���ݵ�ǰԤ��ɿ��ԣ�����������Ĳ��
        pop( pop(:, 1) > pophalf(1, 1), 1 ) = pophalf(1, 1); %��С������Χ
        pop( pop(:, 1) < pophalf(1, 2), 1 ) = pophalf(1, 2);
        pop( pop(:, 2) > pophalf(2, 1), 2 ) = pophalf(2, 1); %��С������Χ
        pop( pop(:, 2) < pophalf(2, 2), 2 ) = pophalf(2, 2);
        pop( pop(:, 3) > pophalf(3, 1), 3 ) = pophalf(3, 1); %��С������Χ
        pop( pop(:, 3) < pophalf(3, 2), 3 ) = pophalf(3, 2);
    else
        pop( pop > popmax ) = popmax;
        pop( pop < popmin ) = popmin;
    end
    
    %�������ӳ�ʼ����Ӧֵ
    [fitness, index] = CC(V1, ppi, pop, C_initial, IndeX, Parameter.sizepop );
    IndeX = cat(1, IndeX, index ); %��ϼ�¼
    FitnesS = cat(1, FitnesS, fitness );
    
    %���弫ֵ��Ⱥ�弫ֵ����
    person = fitness > fitnessgbest; %���弫ֵ����
    gbest( person, :) = pop( person, :);
    fitnessgbest( person ) = fitness( person );
    
    allperson = find( fitness == max( fitness ) ); %Ⱥ�弫ֵ����
    if ~isempty( allperson ) %��ֹallperson����δ֪����
        if fitness( allperson(1) ) > fitnesszbest
            zbest = pop( allperson(1), : );
            fitnesszbest = fitness( allperson(1) );
        end
    end
    
    result(i) = fitnesszbest;
    if i > 1 && (fitnesszbest - result(i-1)) < Parameter.Error %�����������
        end_break = end_break + 1;
    else
        end_break = 1;
    end
    
    if (1 - fitnesszbest) < Parameter.Error || end_break >= end_break_num %�ȶ�����
        break
    end
    
end
end

function [C, index] = CC( V1, ppi, Sxyz, C_initial, IndeX, sizepop )
n = ppi.n1;
m = ppi.m1;
l = ppi.l1;
M = ppi.M;
Sub = ppi.Sub;

x = ppi.Sub*(ppi.xg-1) + 1;
y = ppi.Sub*(ppi.yg-1) + 1;
z = ppi.Sub*(ppi.zg-1) + 1;
Sx = x + ppi.ads(Sxyz(:, 1));
Sy = y + ppi.ads(Sxyz(:, 2));
Sz = z + ppi.ads(Sxyz(:, 3));

num = sizepop; %��Ⱥ����
C = C_initial; %���ϵ����ʼ��
index = C; %��¼C�ľ����������ֵ
index_CC = C; %��¼���μ�����ظ�

for p = 1 : num
    sx = Sx(p);
    sy = Sy(p);
    sz = Sz(p);
    
    % ��������߽�
    if sx > Sub*M+1 && sx <= n-Sub*M-1 && sy > Sub*M+1 && sy <=m-Sub*M-1 && sz > Sub*M+1 && sz <= l-Sub*M-1
        index(p) = sx + (sy-1)*n + (sz-1)*n*m; %��¼����������ֵ
        if isempty( find( IndeX == index(p), 1 ) ) %�Ա���������������и���
            if isempty( find( index_CC == index(p), 1 ) ) %�뱾Ⱥ���������
                Lx = sx-Sub*M : Sub : sx+Sub*M;
                Ly = sy-Sub*M : Sub : sy+Sub*M;
                Lz = sz-Sub*M : Sub : sz+Sub*M;
                g = single( V1(Lx, Ly, Lz) ); %ת����ֵĿ�����
                g = g - ppi.ff_line * g(:);  %ת����ֵĿ�����
                C(p) = g(:)' * ppi.ff(:) / ( ppi.ff_sqrt * sqrt( g(:)' * g(:) ) ); % �����׼��Э�������ϵ��
            end
        end
    end
    index_CC(p) = index(p); %��β��¼����ֵ
end
end

function [sp, zncc] = SubPixel( V1, ppi )
% ���������ڵ�ZNCC
C = SubPixelLatiZNCC( V1, ppi );
%[sp, zncc] = SubPixel27Lati( C ); %27�����ڵ����������λ��
[sp, zncc] = SubPixel19Lati( C, ppi );
sp( abs(sp) > 1 ) = 0;
if zncc > 1
    zncc = 1;
end
if zncc < 0
    zncc = 0;
end
end

function C = SubPixelLatiZNCC( V1, ppi )

n = ppi.n1;
m = ppi.m1;
l = ppi.l1;
M = ppi.M;
Sub = ppi.Sub;
C = ppi.C; %���ϵ��

% ������������������������0.5����
x = Sub*(ppi.xg-1) + 1;
y = Sub*(ppi.yg-1) + 1;
z = Sub*(ppi.zg-1) + 1;
Sx = x + ppi.SP(:, 1) + ppi.uvw(1);
Sy = y + ppi.SP(:, 2) + ppi.uvw(2);
Sz = z + ppi.SP(:, 3) + ppi.uvw(3);
index = Sx + (Sy-1)*n + (Sz-1)*n*m; %��¼����������ֵ

for p = 1 : ppi.numSP
    sx = Sx(p);
    sy = Sy(p);
    sz = Sz(p);
    
    if sx > Sub*M+1 && sx <= n-Sub*M-1 && sy > Sub*M+1 && sy <=m-Sub*M-1 && sz > Sub*M+1 && sz <= l-Sub*M-1
        same_num = find( ppi.IndeX == index(p) ); %���¼ƥ��
        if isempty( same_num ) %û�м����
            Lx = sx-Sub*M : Sub : sx+Sub*M;
            Ly = sy-Sub*M : Sub : sy+Sub*M;
            Lz = sz-Sub*M : Sub : sz+Sub*M;
            g = single( V1(Lx, Ly, Lz) ); %ת����ֵĿ�����
            g = g - ppi.ff_line * g(:);  %ת����ֵĿ�����
            C(p) = g(:)' * ppi.ff(:) / ( ppi.ff_sqrt * sqrt( g(:)' * g(:) ) ); % �����׼��Э�������ϵ��
        else
            C(p) = ppi.FitnesS( same_num(1) ); %��ֵ�������ֵ
        end
    end
end
end

function [sp, zncc] = SubPixel19Lati( C, ppi )
% Curve-fitting ���������λ��
sp = ppi.sp;
% 8�㷽�����====================================
a0 = C(1);
a1 = ( C(2) - C(3) ) / 2;
a2 = ( C(4) - C(5) ) / 2;
a3 = ( C(6) - C(7) ) / 2;
a4 = ( C(8) + C(9) - C(10) - C(11) ) / 4;
a5 = ( C(12) + C(13) - C(14) - C(15) ) / 4;
a6 = ( C(16) + C(17) - C(18) - C(19) ) / 4;
a7 = ( C(2) + C(3) ) / 2 - C(1);
a8 = ( C(4) + C(5) ) / 2 - C(1);
a9 = ( C(6) + C(7) ) / 2 - C(1);

% 12�����=====================================
a11 = 1/8*( C(8) + C(10) - C(11) - C(9) + C(12) + C(14) - C(15) - C(13) );
a22 = 1/8*( C(8) + C(11) - C(9) - C(10) + C(18) + C(16) - C(19) - C(17) );
a33 = 1/8*( C(15) + C(12) - C(13) - C(14) + C(16) + C(19) - C(18) - C(17) );

c1 = 1/8*( C(8) + C(11) + C(9) + C(10) + C(15) + C(12) + C(13) + C(14) - ...
    C(18) - C(16) - C(19) - C(17) ) - 1/2*a0;
c2 = 1/8*( C(8) + C(11) + C(9) + C(10) - C(15) - C(12) - C(13) - C(14) + ...
    C(18) + C(16) + C(19) + C(17) ) - 1/2*a0;
c3 = 1/8*( -C(8) - C(11) - C(9) - C(10) + C(15) + C(12) + C(13) + C(14) + ...
    C(18) + C(16) + C(19) + C(17) ) - 1/2*a0;

%�˲��������˼�ֵλ�ã�������Ҫ���ֵ
a1 = (a1 + a11) / 2;
a2 = (a2 + a22) / 2;
a3 = (a3 + a33) / 2;

a7 = (a7 + c1) / 2;
a8 = (a8 + c2) / 2;
a9 = (a9 + c3) / 2;

b0 = a4 * a4 - 4 * a7 * a8;
b1 = 2 * a2 * a7 - a1 * a4;
b2 = 2 * a6 * a7 - a4 * a5;
b3 = a4 * a5 - 2 * a6 * a7;
b4 = 2 * a3 * a7 - a1 * a5;
b5 = 4 * a7 * a9 - a5 * a5;

F1 = b0 * b5 - b2 * b3;
F2 = b1 * b5 - b2 * b4;
F3 = b1 * b3 - b0 * b4;

sp(1) = -( a1 * F1 + a4 * F2 + a5 * F3 ) / ( 2 * a7 * F1 );
sp(2) = F2 / F1;
sp(3) = F3 / F1;

sp( isnan(sp) ) = 0;
zncc = a0 + a1*sp(1) + a2*sp(2) + a3*sp(3) ...
    + a4*sp(1)*sp(2) + a5*sp(1)*sp(3) + a6*sp(2)*sp(3) ...
    + a7*sp(1)^2 + a8*sp(2)^2 + a9*sp(3)^2;
end

function [sp, zncc, p] = ICGN3D( V0, V1, ppi )
% ���÷������-��˹ţ�ٷ����������
f = ppi.ff;
M = ppi.M;
W = ppi.W;
df = ppi.ff_sqrt;
Sub = ppi.Sub;
ppi.uvw = round( ppi.uvw ); % ת�����ٽ�������
n1 = ppi.n1;
m1 = ppi.n1;
l1 = ppi.l1;

p = [ ppi.uvw(1), ppi.p(2), ppi.p(3), ppi.p(4), ...
    ppi.uvw(2), ppi.p(6), ppi.p(7), ppi.p(8), ...
    ppi.uvw(3), ppi.p(10), ppi.p(11), ppi.p(12) ];
p0 = p; % ��¼��ֵ

W(1, :) = [ 1+p(2), p(3), p(4), p(1) ];
W(2, :) = [ p(6), 1+p(7), p(8), p(5) ];
W(3, :) = [ p(10), p(11), 1+p(12), p(9) ];
dW = ppi.dW;
W = W * dW;

% ����ο�����΢��
fx1 = single( V0( ppi.xf-M-1 : ppi.xf+M-1, ppi.yf -M :ppi.yf+M, ppi.zf -M :ppi.zf+M ) );
fx2 = single( V0( ppi.xf-M+1 : ppi.xf+M+1, ppi.yf -M :ppi.yf+M, ppi.zf -M :ppi.zf+M ) );
fy1 = single( V0( ppi.xf-M : ppi.xf+M, ppi.yf -M-1 :ppi.yf+M-1, ppi.zf -M :ppi.zf+M ) );
fy2 = single( V0( ppi.xf-M : ppi.xf+M, ppi.yf -M+1 :ppi.yf+M+1, ppi.zf -M :ppi.zf+M ) );
fz1 = single( V0( ppi.xf-M : ppi.xf+M, ppi.yf -M :ppi.yf+M, ppi.zf -M-1 :ppi.zf+M-1 ) );
fz2 = single( V0( ppi.xf-M : ppi.xf+M, ppi.yf -M :ppi.yf+M, ppi.zf -M+1 :ppi.zf+M+1 ) );
fx = ( fx1(:) - fx2(:) ) / 2 / Sub;
fy = ( fy1(:) - fy2(:) ) / 2 / Sub;
fz = ( fz1(:) - fz2(:) ) / 2 / Sub;

%�����ſ˱Ⱦ���ͺ�ɭ����=========================
fxyz = [ fx, fx, fx, fx, fy, fy, fy, fy, fz, fz, fz, fz ];
J = bsxfun( @times, fxyz, single(ppi.JacPre) );
H_inversion = ( J' * J )^(-1);

% ���е�������======================================
r = ppi.r;    %��¼zncc
tp = ppi.tp;    %��¼λ��
x = Sub * ( ppi.xg - 1 ) + 1;    % �任����ϵ
y = Sub * ( ppi.yg - 1 ) + 1;
z = Sub * ( ppi.zg - 1 ) + 1;

for num = 1 : ppi.tn %����������
    
    bk = 0; % ����Ƿ񳬳��߽�
    sxyz = double( round( [ x + W(1, 4), y + W(2, 4), z + W(3, 4) ] ) );
    
    if any( isnan( sxyz ) ) %�����쳣
        break
    end
    
    X = int32( sxyz(1) + ppi.U * W(1, 1) + ppi.V * W(1, 2) + ppi.Ww * W(1, 3) );
    Y = int32( sxyz(2) + ppi.U * W(2, 1) + ppi.V * W(2, 2) + ppi.Ww * W(2, 3) );
    Z = int32( sxyz(3) + ppi.U * W(3, 1) + ppi.V * W(3, 2) + ppi.Ww * W(3, 3) );
    
    dx = ppi.Umax*abs( W(1, 1) ) + ppi.Vmax*abs( W(1, 2) ) + ppi.Wmax*abs( W(1, 3) );
    dy = ppi.Umax*abs( W(2, 1) ) + ppi.Vmax*abs( W(2, 2) ) + ppi.Wmax*abs( W(2, 3) );
    dz = ppi.Umax*abs( W(3, 1) ) + ppi.Vmax*abs( W(3, 2) ) + ppi.Wmax*abs( W(3, 3) );
    
    if sxyz(1) - M - dx < 0;         X( X < 1 ) = 1;          bk = 1;          end
    if sxyz(1) + M + dx > n1;     X( X > n1 ) = n1;      bk = 1;          end
    if sxyz(2) - M - dy < 0;         Y( Y < 1 ) = 1;          bk = 1;          end
    if sxyz(2) + M + dy > m1;    Y( Y > m1 ) = m1;    bk = 1;          end
    if sxyz(3) - M - dz < 0;         Z( Z < 1 ) = 1;          bk = 1;          end
    if sxyz(3) + M + dz > l1;      Z( Z > l1 ) = l1;         bk = 1;          end
    
    LXYZ = (X + n1*Y + (n1*m1)*Z) - (n1 + n1*m1);
    g = single( V1( LXYZ ) );
    g = g - ppi.ff_line * g(:);
    dg = sqrt( g(:)' * g(:) );
    r(num) = f(:)' * g(:) / dg / df; %�������ϵ��
    
    Q = ( f(:) - (df/dg) * g(:) )' * J;    % ����λ������
    dp = ( -Q * H_inversion )';
    dp( isnan(dp) ) = 0; % ����
    if bk > 1;    dp = dp / 2;    end % ���б߽�����
    
    % �ж��Ƿ�����������=======================
    dx = ppi.Umax*abs(dp(2)) + ppi.Vmax*abs(dp(3)) + ppi.Wmax*abs(dp(4));
    dy = ppi.Umax*abs(dp(6)) + ppi.Vmax*abs(dp(7)) + ppi.Wmax*abs(dp(8));
    dz = ppi.Umax*abs(dp(10)) + ppi.Vmax*abs(dp(11)) + ppi.Wmax*abs(dp(12));
    
    if all( abs( dp( [1, 5, 9] ) ) < 1 )  && all( round( [dx, dy, dz] ) < 1 ) % ������λ�ƺ���״�ı�
        p = p + dp';
        tp(num, :) = p;
        break
    end
    
    p = p + dp';
    p( abs( p - p0 ) > 10 ) = p0( abs( p - p0 ) > 10); %��ֹ���Է�ɢ
    p( [1, 5, 9] ) = round( p( [1, 5, 9] ) ); %�ٽ����� % ��ֹ��������ۼ�
    tp(num, :) = p;
    
    W(1, :) = [ 1+p(2), p(3), p(4), p(1) ];
    W(2, :) = [ p(6), 1+p(7), p(8), p(5) ];
    W(3, :) = [ p(10), p(11), 1+p(12), p(9) ];
    
end

tp = tp( ~isnan( r ) & ~isinf( r ), : ); %�޳��쳣
r = r(  ~isnan( r ) & ~isinf( r ) );
get_num = find( r == max(r) );

if isempty( get_num )
    sp = ppi.uvw * 0;
    zncc = ppi.zncc;
    p = p * 0;
else
    zncc = r(get_num(1));
    p = tp( get_num(1), :);
    sp = [ p(1), p(5), p(9) ] - ppi.uvw';
end

sp( abs( sp - ppi.uvw' ) > 10 ) = 0; % IC-GN�����뾶һ��Ϊ7

end
