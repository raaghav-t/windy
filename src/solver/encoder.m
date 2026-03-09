% ENCODER
% -------
% Convert an 8x8 board + side-to-move into the state vector used
% everywhere else in this project.
%
% State format (65x1):
%   x(1:64)  -> board squares, column-major after transpose (board')
%   x(65)    -> turn flag, 1 for white to move, -1 for black to move
%
% Piece codes used by this KRK project:
%   10  = white king
%    5  = white rook
%  -10  = black king
%    0  = empty square
function x = encoder(chessboard, turn)
    % Basic input validation so downstream functions can assume shape/type.
    if ~isequal(size(chessboard), [8, 8])
        error('Wrong size board: expected 8x8.');
    end

    % Turn must be one of the two legal values used by the solver.
    if turn ~= -1 && turn ~= 1
        error('Turn must be -1 or 1.');
    end

    % Store board in the same orientation expected by reshape(... )'
    % used in solver/helper functions.
    x = chessboard';
    x = x(:);

    % Append side-to-move.
    x = [x; turn];
end
