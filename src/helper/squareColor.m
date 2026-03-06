% this function will take a row and column and give back -1 for white 1 for black square
function color = squareColor(row,col)
    if row > 8 | col > 8 | row < 1 | col < 1
        fprintf("whoops you are out of bounds :(")
    elseif (mod(row, 2) == 0 & mod(col, 2) == 0) | (mod(row, 2) == 1 & mod(col, 2) == 1)
        color = 1; % 1 means black
    else
        color = -1; % -1 means white
    end
end