% Cost for minimax search in K+R vs K.
% White minimizes this value, black maximizes it.
function J = cost(x)
    mateScore = 1e6;

    % Terminal condition: black is checkmated (white has won).
    % Use strict turn logic so this only triggers on legal terminal nodes.
    if isCheckmate(x, true)
        J = -mateScore;
        return;
    end

    spaceForBlack = oxygenBKing(x);
    distKings = distance(x);

    % White-centric heuristic: lower is always better for white.
    % Minimax should handle max/min by turn, not this function.
    J = spaceForBlack + distKings;
end
