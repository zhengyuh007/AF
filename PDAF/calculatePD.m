% This file is used for calculating PD for L and R image
% Note that L and R are grey scale image
% clean all previous infor
close all;
clear all;
clc;

% step<1>: read image file as raw
%{
% read left bmp image
imgPath = '../sample1/2PD_FlatField_Y_Left_1.bmp';
%imgPath = '../sample6/2PD_FlatField_Y_Left_6.bmp';
Img1 = imread(imgPath, 'bmp');
figure(1);
subplot(2,1,1);
imshow(Img1);
title('Left PD img')
%read right bmp image
imgPath = '../sample1/2PD_FlatField_Y_Right_1.bmp';
%imgPath = '../sample6/2PD_FlatField_Y_Right_6.bmp';
Img2 = imread(imgPath);
subplot(2,1,2);
imshow(Img2);
title('Right PD img')
%}
% read 16bit raw data from left img
imgPath = '../sample1/2PD_FlatField_Y_Left_1.raw';
fid_raw = fopen(imgPath);
rawdata = fread(fid_raw, 'uint16');
fclose(fid_raw);
width = 2016;
height = 756;
Img1 = zeros(756, 2016);
index = 1;
for i = 1:1: height
    for j = 1:1:width
        Img1(i, j) = rawdata(index, 1);
        index = index + 1;
    end
end

% read 16bit raw data from right img
imgPath = '../sample1/2PD_FlatField_Y_Right_1.raw';
fid_raw = fopen(imgPath);
rawdata = fread(fid_raw, 'uint16');
fclose(fid_raw);
Img2 = zeros(756, 2016);
index = 1;
for i = 1:1:height
    for j = 1:1:width
        Img2(i, j) = rawdata(index, 1);
        index = index + 1;
    end
end
% change data type from double to be uint16
Img1 = uint16(Img1);
Img2 = uint16(Img2);

% step<2>: calculate SAD for each move in [move_min, move_max] and get 3
%          minimal samples(record both SAD and pixel move)
% each time we move right image to 1 pixel(if to left -1,-2.. if to right 1,2...)
move_min = -8;
move_max = 8;
% in (start_x, start_y) to (end_x, end_y) region we calculate PD
start_x = 461; 
start_y = 406;
end_x = 671;
end_y = 556;

fprintf('when move = 0, SAD = %d \n',calculateSAD(start_x, end_x, start_y, end_y, Img1, Img2, 0));
% record minimal 3 samples(3 minimal SAD and their pixel move)
% minThreeSAD(1) < minThreeSAD(2) < minThreeSAD(3)
minThreeSAD = zeros(1, 3);
minThreeIndex = zeros(1,3);
for i = 1:1:3
    minThreeSAD(1) = intmax('int64');
    minThreeSAD(2) = intmax('int64');
    minThreeSAD(3) = intmax('int64');
end
SADlist = zeros(1, move_max - move_min + 1);
for move = move_min : 1 : move_max
    % interface: function SAD = calculateSAD(start_x, end_x, start_y, end_y, L, R, move)
    SAD = calculateSAD(start_x, end_x, start_y, end_y, Img1, Img2, move);
    SADlist(move - move_min + 1) = SAD;
    % update last three minimal values
    if SAD < minThreeSAD(1)
        minThreeSAD(3) = minThreeSAD(2);
        minThreeIndex(3) = minThreeIndex(2);
        minThreeSAD(2) = minThreeSAD(1);
        minThreeIndex(2) = minThreeIndex(1);
        minThreeSAD(1) = SAD;
        minThreeIndex(1) = move;
    elseif SAD < minThreeSAD(2)
        minThreeSAD(3) = minThreeSAD(2);
        minThreeIndex(3) = minThreeIndex(2);
        minThreeSAD(2) = SAD;
        minThreeIndex(2) = move;
    elseif SAD < minThreeSAD(3)
        minThreeSAD(3) = SAD;
        minThreeIndex(3) = move;
    end
end

% step<3>: if minimal point is not the boundary
%          we use minimal 3 samples to fit a quadratic curve (y = a*x*x + b*x+ c)
%          and get PD = -b/2a
%          else we take minimal point pixel move as PD
PD = 0;
if minThreeIndex(1) == move_min || minThreeIndex(1) == move_max
    PD = minThreeIndex(1);
else
    % use MATLAB library to do fitting
    % quad(1,2,3) = (a,b,c)
    quad = polyfit(minThreeIndex, minThreeSAD, 2);
    a = quad(1);
    b = quad(2);
    PD = -b/(2*a);
end 

% Bonus: plot (y = SAD, x = pixel move) curve and fitting quadratic curve if exist
fprintf('PD = %d \n', PD);
figure(2);
index = move_min : 1 : move_max;
plot(index, SADlist, 'r');
title('SAD - pixel move');
ylabel('SAD');
xlabel('move(pixel)');
hold on;
quad = polyfit(minThreeIndex, minThreeSAD, 2);
a = quad(1);
b = quad(2);
c = quad(3);
quadFunc = zeros(1, move_max - move_min + 1);
for move = move_min : 1 : move_max
    quadFunc(move - move_min + 1) = a * move * move + b * move + c;
end
PD = -b/(2*a);
fprintf('By fitting using 3 minimal samples PD = %d \n', PD);
plot(index, quadFunc, 'b');
hold on;



    