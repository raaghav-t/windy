% ISSTALEMATE
% -----------
% Detect stalemate against black king in KRK.
%
% Inputs:
%   x                - encoded 65x1 state
%   requireBlackTurn - optional logical flag:
%                      true  -> only report stalemate if turn == -1
%                      false -> board-pattern stalemate check regardless of turn
function stale = isStalemate(x, requireBlackTurn)
    board = reshape(x(1:64), 8, 8)';
    turn = x(65);

    if nargin < 2
        requireBlackTurn = false;
    end

    if requireBlackTurn && turn ~= -1
        stale = false;
        return;
    end

    % Need all three pieces for KRK stalemate logic.
    hasWKing = any(board(:) == 10);
    hasRook = any(board(:) == 5);
    hasBKing = any(board(:) == -10);
    if ~hasWKing || ~hasRook || ~hasBKing
        stale = false;
        return;
    end

    % Stalemate is "not checkmate" and "no legal moves".
    if isCheckmate(x, requireBlackTurn)
        stale = false;
        return;
    end

    stale = isempty(possibleMoves(x));
end
