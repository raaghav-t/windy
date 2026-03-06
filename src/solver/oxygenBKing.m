% Calculates black king "oxygen": number of legal squares available
% in K+R vs K, given the current board.
function area = oxygenBKing(x)
    board = reshape(x(1:64), 8, 8)';

    [rowRook, colRook] = find(board == 5, 1);
    [rowBKing, colBKing] = find(board == -10, 1);
    [rowWKing, colWKing] = find(board == 10, 1);

    if isempty(rowRook) || isempty(rowBKing) || isempty(rowWKing)
        error('Board must contain white rook (5), white king (10), and black king (-10).');
    end

    area = 0;
    for dr = -1:1
        for dc = -1:1
            if dr == 0 && dc == 0
                continue;
            end

            r = rowBKing + dr;
            c = colBKing + dc;

            if r < 1 || r > 8 || c < 1 || c > 8
                continue;
            end

            if r == rowWKing && c == colWKing
                continue;
            end

            if max(abs(r - rowWKing), abs(c - colWKing)) <= 1
                continue;
            end

            if rookAttacksSquare(rowRook, colRook, r, c, rowWKing, colWKing)
                continue;
            end

            area = area + 1;
        end
    end
end

function tf = rookAttacksSquare(rowRook, colRook, row, col, rowWKing, colWKing)
    tf = false;
    if rowRook ~= row && colRook ~= col
        return;
    end

    if rowRook == row
        step = sign(col - colRook);
        c = colRook + step;
        while c ~= col
            if rowWKing == rowRook && colWKing == c
                return;
            end
            c = c + step;
        end
        tf = true;
        return;
    end

    step = sign(row - rowRook);
    r = rowRook + step;
    while r ~= row
        if rowWKing == r && colWKing == colRook
            return;
        end
        r = r + step;
    end
    tf = true;
end
