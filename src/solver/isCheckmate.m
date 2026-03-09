% ISCHECKMATE
% -----------
% Detect checkmate against black king in KRK (white: king+rook, black: king).
%
% Inputs:
%   x                - encoded 65x1 state
%   requireBlackTurn - optional logical flag:
%                      true  -> only report mate if turn == -1
%                      false -> board-pattern mate check regardless of turn
function mate = isCheckmate(x, requireBlackTurn)
    % Decode board and side-to-move.
    board = reshape(x(1:64), 8, 8)';
    turn = turnFromCounter(x(65));

    % Default behavior: pattern-based detection (not strict about turn).
    if nargin < 2
        requireBlackTurn = false;
    end

    % Strict mode: checkmate is only meaningful if black must respond now.
    if requireBlackTurn && turn ~= -1
        mate = false;
        return;
    end

    % Locate pieces.
    [rowR, colR] = find(board == 5, 1);
    [rowW, colW] = find(board == 10, 1);
    [rowB, colB] = find(board == -10, 1);

    % Missing kings -> not a valid checkmate state for this solver.
    if isempty(rowW) || isempty(rowB)
        mate = false;
        return;
    end

    % Without rook, white cannot deliver checkmate in KRK.
    if isempty(rowR)
        mate = false;
        return;
    end

    % Checkmate requires black king currently in check...
    inCheck = squareAttackedByWhite(rowB, colB, rowR, colR, rowW, colW);
    if ~inCheck
        mate = false;
        return;
    end

    % ...and no legal black king move to escape.
    legalMoves = countLegalBlackKingMoves(board, rowB, colB, rowR, colR, rowW, colW);
    mate = (legalMoves == 0);
end

% Count legal black king moves in current position.
function n = countLegalBlackKingMoves(board, rowB, colB, rowR, colR, rowW, colW)
    n = 0;
    for dr = -1:1
        for dc = -1:1
            % Skip standing still.
            if dr == 0 && dc == 0
                continue;
            end

            % Candidate destination.
            r = rowB + dr;
            c = colB + dc;
            if r < 1 || r > 8 || c < 1 || c > 8
                continue;
            end

            % Black king may move to empty square or capture rook.
            piece = board(r, c);
            if piece ~= 0 && piece ~= 5
                continue;
            end

            % Kings cannot end adjacent.
            if max(abs(r - rowW), abs(c - colW)) <= 1
                continue;
            end

            % If rook is captured, remove rook from attack map for test.
            nextRowR = rowR;
            nextColR = colR;
            if piece == 5
                % Capturing rook is legal if destination is not protected by white king.
                nextRowR = -1;
                nextColR = -1;
            end

            % Destination cannot be attacked by white.
            if squareAttackedByWhite(r, c, nextRowR, nextColR, rowW, colW)
                continue;
            end

            % Found one legal escape square.
            n = n + 1;
        end
    end
end

% True if white attacks (row, col) via king or rook.
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

    % White rook attack with king-as-blocker ray tracing.
    if rookAttacksSquare(rowR, colR, row, col, rowW, colW)
        tf = true;
    end
end

% Rook line attack with white king blocking between rook and target.
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

function t = turnFromCounter(counter)
    % Counter decoder:
    %   even -> white (+1), odd -> black (-1)
    if mod(counter, 2) == 0
        t = 1;
    else
        t = -1;
    end
end
