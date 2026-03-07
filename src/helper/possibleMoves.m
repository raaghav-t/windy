% Return all legal next states from an encoded KRK position.
% Each column of `moves` is a 65x1 encoded state vector.
function moves = possibleMoves(x)
    board = reshape(x(1:64), 8, 8)';
    turn = x(65);
    moves = zeros(65, 0);

    % Terminal position: do not generate continuations from checkmate.
    if isCheckmate(x)
        return;
    end

    [rowW, colW] = find(board == 10, 1);
    [rowR, colR] = find(board == 5, 1);
    [rowB, colB] = find(board == -10, 1);

    if isempty(rowW) || isempty(rowR) || isempty(rowB)
        error('Board must contain white king (10), white rook (5), and black king (-10).');
    end

    nextTurn = -turn;

    if turn == 1
        % White to move: white king moves.
        for dr = -1:1
            for dc = -1:1
                if dr == 0 && dc == 0
                    continue;
                end

                r = rowW + dr;
                c = colW + dc;

                if ~inBounds(r, c)
                    continue;
                end

                if board(r, c) ~= 0
                    continue;
                end

                % Kings cannot be adjacent.
                if max(abs(r - rowB), abs(c - colB)) <= 1
                    continue;
                end

                nextBoard = board;
                nextBoard(rowW, colW) = 0;
                nextBoard(r, c) = 10;
                moves(:, end + 1) = encodeState(nextBoard, nextTurn);
            end
        end

        % White to move: rook moves.
        directions = [-1 0; 1 0; 0 -1; 0 1];
        for k = 1:size(directions, 1)
            dr = directions(k, 1);
            dc = directions(k, 2);
            r = rowR + dr;
            c = colR + dc;

            while inBounds(r, c)
                if board(r, c) ~= 0
                    break;
                end

                nextBoard = board;
                nextBoard(rowR, colR) = 0;
                nextBoard(r, c) = 5;
                moves(:, end + 1) = encodeState(nextBoard, nextTurn);

                r = r + dr;
                c = c + dc;
            end
        end
    else
        % Black to move: black king moves.
        for dr = -1:1
            for dc = -1:1
                if dr == 0 && dc == 0
                    continue;
                end

                r = rowB + dr;
                c = colB + dc;

                if ~inBounds(r, c)
                    continue;
                end

                target = board(r, c);
                if target ~= 0 && target ~= 5
                    continue;
                end

                % Kings cannot be adjacent.
                if max(abs(r - rowW), abs(c - colW)) <= 1
                    continue;
                end

                % If black captures rook, rook is removed before attack check.
                nextRowR = rowR;
                nextColR = colR;
                if target == 5
                    nextRowR = -1;
                    nextColR = -1;
                end

                if squareAttackedByWhite(r, c, nextRowR, nextColR, rowW, colW)
                    continue;
                end

                nextBoard = board;
                nextBoard(rowB, colB) = 0;
                if target == 5
                    nextBoard(rowR, colR) = 0;
                end
                nextBoard(r, c) = -10;
                moves(:, end + 1) = encodeState(nextBoard, nextTurn);
            end
        end
    end
end

function y = encodeState(board, turn)
    y = board';
    y = y(:);
    y = [y; turn];
end

function tf = inBounds(r, c)
    tf = (r >= 1) && (r <= 8) && (c >= 1) && (c <= 8);
end

function tf = squareAttackedByWhite(row, col, rowR, colR, rowW, colW)
    tf = false;

    if max(abs(row - rowW), abs(col - colW)) <= 1
        tf = true;
        return;
    end

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
