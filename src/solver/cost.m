% Cost for minimax search in K+R vs K.
% White minimizes this value, black maximizes it.
function J = cost(x)
    turn = x(65);

    spaceForBlack = oxygenBKing(x);
    distKings = distance(x);

    baseCost = spaceForBlack + distKings + turn;

    if turn == 1
        % White to move: keep the natural objective (smaller is better).
        J = baseCost;
    else
        % Black to move: invert so larger black advantage is larger J.
        J = -baseCost;
    end
end
