% clean all previous infor
close all;
clear all;
clc;

% read left bmp image
imgPath = '../sample1/2PD_FlatField_Y_Left_1.bmp';
Img1 = imread(imgPath);
figure(1);
subplot(2,1,1);
imshow(Img1);
title('Left PD img')
%read right bmp image
imgPath = '../sample1/2PD_FlatField_Y_Right_1.bmp';
Img2 = imread(imgPath);
subplot(2,1,2);
imshow(Img2);
title('Right PD img')

% calculate SAD
start_x = 1; 
end_x = 100;
start_y = 1;
end_y = 100;
diffMatrix = zeros(end_y - start_y + 1, end_x - start_x + 1);
SAD = uint32(0);
numOfZero = 0;
for i = start_y:1:end_y
    for j = start_x:1:end_x
        %note that Img data is default 8bit, if u don't change type 
        % to be 16bit the SAD will be stuck at 255
        diff = uint32(abs(Img1(i,j) - Img2(i,j)));
        SAD = SAD + diff;
        if diff == 0
            numOfZero = numOfZero + 1;
        end
        diffMatrix(i,j) = diff;
        %fprintf('pos:(%i, %i) pixel difference: %i \n', i,j, diff);
    end
end
fprintf('SAD = %d \n', SAD);
fprintf('sum of absolute difference matrix by library = %d \n', sum(sum(diffMatrix)));
fprintf('number of difference equals zero = %d \n', numOfZero);
fprintf('number of difference equals zero by library = %d \n', length(find(diffMatrix == 0)));

%{
[x,y] = meshgrid(1:100, 1:100);
figure(2);
surf(x,y, diffMatrix);

figure(3)
plot(diffMatrix(1,1:100))
%}


    