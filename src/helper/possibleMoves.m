% POSSIBLEMOVES
% -------------
% Generate all legal next states from current KRK state x.
%
% Output format:
%   moves is 65xN
%   each column is one legal child state after exactly one ply.
function moves = possibleMoves(x)
    % Decode state.
    board = reshape(x(1:64), 8, 8)';
    turn = x(65);

    % Start with empty child list; append columns as legal moves are found.
    moves = zeros(65, 0);

    % Terminal position: do not continue from checkmate node.
    if isCheckmate(x)
        return;
    end

    % Locate pieces.
    [rowW, colW] = find(board == 10, 1);
    [rowR, colR] = find(board == 5, 1);
    [rowB, colB] = find(board == -10, 1);

    % Missing kings -> invalid, no children.
    if isempty(rowW) || isempty(rowB)
        return;
    end

    % No rook (already captured) -> terminal in this KRK model.
    if isempty(rowR)
        % Treat rook-captured states as terminal for KRK search.
        return;
    end

    % Side to move flips after any legal move.
    nextTurn = -turn;

    if turn == 1
        % =============================================================
        % WHITE TO MOVE
        % 1) White king moves (8 neighboring squares).
        % =============================================================
        for dr = -1:1
            for dc = -1:1
                if dr == 0 && dc == 0
                    continue;
                end

                % Candidate king destination.
                r = rowW + dr;
                c = colW + dc;

                % Must stay on board.
                if ~inBounds(r, c)
                    continue;
                end

                % King cannot move into occupied square here
                % (white rook and black king both block).
                if board(r, c) ~= 0
                    continue;
                end

                % Kings cannot be adjacent after move.
                if max(abs(r - rowB), abs(c - colB)) <= 1
                    continue;
                end

                % Build child board and encode.
                nextBoard = board;
                nextBoard(rowW, colW) = 0;
                nextBoard(r, c) = 10;
                moves(:, end + 1) = encodeState(nextBoard, nextTurn);
            end
        end

        % =============================================================
        % 2) White rook moves (slide in 4 orthogonal directions).
        % =============================================================
        directions = [-1 0; 1 0; 0 -1; 0 1];
        for k = 1:size(directions, 1)
            dr = directions(k, 1);
            dc = directions(k, 2);
            r = rowR + dr;
            c = colR + dc;

            while inBounds(r, c)
                % Rook ray stops at first occupied square.
                if board(r, c) ~= 0
                    break;
                end

                % Every empty square along ray is a legal rook destination.
                nextBoard = board;
                nextBoard(rowR, colR) = 0;
                nextBoard(r, c) = 5;
                moves(:, end + 1) = encodeState(nextBoard, nextTurn);

                r = r + dr;
                c = c + dc;
            end
        end
    else
        % =============================================================
        % BLACK TO MOVE
        % Black king can move to empty square or capture rook, provided
        % destination is legal (not adjacent to white king, not attacked).
        % =============================================================
        for dr = -1:1
            for dc = -1:1
                if dr == 0 && dc == 0
                    continue;
                end

                % Candidate black king destination.
                r = rowB + dr;
                c = colB + dc;

                if ~inBounds(r, c)
                    continue;
                end

                % Allowed targets:
                %   0 (empty) or 5 (capture rook).
                target = board(r, c);
                if target ~= 0 && target ~= 5
                    continue;
                end

                % Kings cannot be adjacent.
                if max(abs(r - rowW), abs(c - colW)) <= 1
                    continue;
                end

                % Attack check uses "post-move board":
                % if rook captured, remove rook from attack map first.
                nextRowR = rowR;
                nextColR = colR;
                if target == 5
                    nextRowR = -1;
                    nextColR = -1;
                end

                % Black king cannot move onto white-attacked square.
                if squareAttackedByWhite(r, c, nextRowR, nextColR, rowW, colW)
                    continue;
                end

                % Build child board and encode.
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

% Encode local board+turn into shared 65x1 state format.
function y = encodeState(board, turn)
    y = board';
    y = y(:);
    y = [y; turn];
end

% Bounds helper for board indices.
function tf = inBounds(r, c)
    tf = (r >= 1) && (r <= 8) && (c >= 1) && (c <= 8);
end

% White attacks a square if white king adjacent, or rook attacks along ray.
function tf = squareAttackedByWhite(row, col, rowR, colR, rowW, colW)
    tf = false;

    % King attack.
    if max(abs(row - rowW), abs(col - colW)) <= 1
        tf = true;
        return;
    end

    % No rook => no rook attack.
    if rowR < 1 || colR < 1
        return;
    end

    % Rook line attack.
    if rookAttacksSquare(rowR, colR, row, col, rowW, colW)
        tf = true;
    end
end

% Rook ray attack with white king acting as blocker.
function tf = rookAttacksSquare(rowR, colR, row, col, rowW, colW)
    tf = false;
    if rowR ~= row && colR ~= col
        return;
    end

    % Horizontal line.
    if rowR == row
        step = sign(col - colR);
        c = colR + step;
        while c ~= col
            % White king blocks rook ray.
            if rowW == rowR && colW == c
                return;
            end
            c = c + step;
        end
        tf = true;
        return;
    end

    % Vertical line.
    step = sign(row - rowR);
    r = rowR + step;
    while r ~= row
        % White king blocks rook ray.
        if rowW == r && colW == colR
            return;
        end
        r = r + step;
    end
    tf = true;
end
