% COST
% ----
% Heuristic evaluation function used by minimax.
%
% Convention:
%   Lower cost = better for white (white is minimizing player).
%   Higher cost = better for black (black is maximizing player).
%
% This function is intentionally "white-centric".
% Minimax handles max/min by turn at search time.
function J = cost(x)
    % Large terminal magnitude so forced outcomes dominate heuristics.
    mateScore = 1e6;

    % Decode board for piece-presence checks.
    board = reshape(x(1:64), 8, 8)';

    % Detect required pieces for KRK.
    hasWKing = any(board(:) == 10);
    hasRook = any(board(:) == 5);
    hasBKing = any(board(:) == -10);

    if ~hasWKing || ~hasBKing
        % Invalid/corrupt state fallback (treat as very bad for white).
        J = mateScore;
        return;
    end

    if ~hasRook
        % If rook is gone, white can no longer force mate in KRK.
        J = mateScore;
        return;
    end

    % Terminal win for white.
    % strict turn mode ensures only legal "black-to-move mate" is rewarded.
    if isCheckmate(x, true)
        J = -mateScore;
        return;
    end

    % Main heuristic terms:
    % 1) black king mobility ("oxygen") -> white wants this small
    % 2) king distance -> white often wants opposition/proximity effects
    spaceForBlack = oxygenBKing(x);
    distKings = distance(x);

    % Combined white-centric score.
    J = spaceForBlack + distKings;
end
