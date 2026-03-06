% True when position is checkmate against the black king in K+R vs K.
% Expects encoded state vector x with x(65) = 1 (white) or -1 (black) to move.
function mate = isCheckmate(x)
    board = reshape(x(1:64), 8, 8)';
    turn = x(65);

    % In this project, checkmate is only relevant when black is to move.
    if turn ~= -1
        mate = false;
        return;
    end

    [rowR, colR] = find(board == 5, 1);
    [rowW, colW] = find(board == 10, 1);
    [rowB, colB] = find(board == -10, 1);

    if isempty(rowR) || isempty(rowW) || isempty(rowB)
        error('Board must contain white rook (5), white king (10), and black king (-10).');
    end

    inCheck = squareAttackedByWhite(rowB, colB, rowR, colR, rowW, colW);
    if ~inCheck
        mate = false;
        return;
    end

    legalMoves = countLegalBlackKingMoves(board, rowB, colB, rowR, colR, rowW, colW);
    mate = (legalMoves == 0);
end

function n = countLegalBlackKingMoves(board, rowB, colB, rowR, colR, rowW, colW)
    n = 0;
    for dr = -1:1
        for dc = -1:1
            if dr == 0 && dc == 0
                continue;
            end

            r = rowB + dr;
            c = colB + dc;
            if r < 1 || r > 8 || c < 1 || c > 8
                continue;
            end

            piece = board(r, c);
            if piece ~= 0 && piece ~= 5
                continue;
            end

            if max(abs(r - rowW), abs(c - colW)) <= 1
                continue;
            end

            nextRowR = rowR;
            nextColR = colR;
            if piece == 5
                % Capturing rook is legal if destination is not protected by white king.
                nextRowR = -1;
                nextColR = -1;
            end

            if squareAttackedByWhite(r, c, nextRowR, nextColR, rowW, colW)
                continue;
            end

            n = n + 1;
        end
    end
end

function tf = squareAttackedByWhite(row, col, rowR, colR, rowW, colW)
    tf = false;

    % White king attacks adjacent squares.
    if max(abs(row - rowW), abs(col - colW)) <= 1
        tf = true;
        return;
    end

    % White rook attacks along file/rank if present.
    if rowR < 1 || colR < 1
        return;
    end

    if rookAttacksSquare(rowR, colR, row, col, rowW, colW)
        tf = true;
    end
end

function tf = rookAttacksSquare(rowR, colR, row, col, rowW, colW)
    tf = false;
    if rowR ~= row && colR ~= col
        return;
    end

    if rowR == row
        step = sign(col - colR);
        c = colR + step;
        while c ~= col
            if rowW == rowR && colW == c
                return;
            end
            c = c + step;
        end
        tf = true;
        return;
    end

    step = sign(row - rowR);
    r = rowR + step;
    while r ~= row
        if rowW == r && colW == colR
            return;
        end
        r = r + step;
    end
    tf = true;
end
