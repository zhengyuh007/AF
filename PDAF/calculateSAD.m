% calculate SAD for one time
function SAD = calculateSAD(start_x, end_x, start_y, end_y, L, R, move)

SAD = uint32(0);
for i = start_y:1:end_y
    for j = start_x:1:end_x
        % get the real region (deal with out of boundary) j >= 0 or j <= size(R, 2)
        posXR = j + move;
        if posXR < 0
            posXR = 0;
        end
        if posXR > size(R,2)
            posXR = size(R,2);
        end
        % note that Img data is default 8bit, if u don't change type 
        % to be 16bit the SAD will be stuck at 255
        % note that we should change uint16 -> int16 otherwise if result is
        % < 0 since L and R are uint16 by default this is going to be 0
        diff = uint32(abs(int16(L(i,j)) - int16(R(i,posXR))));
        SAD = SAD + diff;
    end
end
% end of function for calculate PD
