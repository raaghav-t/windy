% SQUARECOLOR
% -----------
% Return chessboard square color from (row, col).
%
% Output convention used here:
%   color =  1  -> black square
%   color = -1  -> white square
function color = squareColor(row, col)
    % Validate board bounds.
    if row > 8 | col > 8 | row < 1 | col < 1
        fprintf("whoops you are out of bounds :(")

    % Even/even or odd/odd index pairs are black squares.
    elseif (mod(row, 2) == 0 & mod(col, 2) == 0) | (mod(row, 2) == 1 & mod(col, 2) == 1)
        color = 1; % 1 means black
    else
        color = -1; % -1 means white
    end
end
