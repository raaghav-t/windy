% OXYGENBKING
% -----------
% Compute black king "oxygen":
% number of legal destination squares black king can move to right now.
%
% This is used as a mobility/space term in the evaluation.
% Smaller oxygen means black is more restricted (good for white).
function area = oxygenBKing(x)
    % Decode state vector to board.
    board = reshape(x(1:64), 8, 8)';

    % Locate pieces.
    [rowRook, colRook] = find(board == 5, 1);
    [rowBKing, colBKing] = find(board == -10, 1);
    [rowWKing, colWKing] = find(board == 10, 1);

    % Kings must exist in any valid state.
    if isempty(rowBKing) || isempty(rowWKing)
        error('Board must contain both kings.');
    end

    % Count legal king destinations among the 8 neighboring squares.
    area = 0;
    for dr = -1:1
        for dc = -1:1
            % Skip "no move".
            if dr == 0 && dc == 0
                continue;
            end

            % Candidate black king destination.
            r = rowBKing + dr;
            c = colBKing + dc;

            % Must remain on board.
            if r < 1 || r > 8 || c < 1 || c > 8
                continue;
            end

            % Cannot move onto white king's square.
            if r == rowWKing && c == colWKing
                continue;
            end

            % Kings may not be adjacent after the move.
            if max(abs(r - rowWKing), abs(c - colWKing)) <= 1
                continue;
            end

            % If rook exists, black king cannot step onto rook-attacked squares.
            if ~isempty(rowRook) && rookAttacksSquare(rowRook, colRook, r, c, rowWKing, colWKing)
                continue;
            end

            % If all constraints passed, this destination is legal.
            area = area + 1;
        end
    end
end

% Helper: true if rook attacks target square given white king can block line.
function tf = rookAttacksSquare(rowRook, colRook, row, col, rowWKing, colWKing)
    tf = false;

    % Rook attacks only along same rank/file.
    if rowRook ~= row && colRook ~= col
        return;
    end

    % Horizontal attack path check.
    if rowRook == row
        step = sign(col - colRook);
        c = colRook + step;
        while c ~= col
            % White king blocks rook ray.
            if rowWKing == rowRook && colWKing == c
                return;
            end
            c = c + step;
        end
        tf = true;
        return;
    end

    % Vertical attack path check.
    step = sign(row - rowRook);
    r = rowRook + step;
    while r ~= row
        % White king blocks rook ray.
        if rowWKing == r && colWKing == colRook
            return;
        end
        r = r + step;
    end
    tf = true;
end
