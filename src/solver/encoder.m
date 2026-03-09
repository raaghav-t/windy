% ENCODER
% -------
% Convert an 8x8 board + turn/counter into the state vector used
% everywhere else in this project.
%
% State format (65x1):
%   x(1:64)  -> board squares, column-major after transpose (board')
%   x(65)    -> move counter (recommended):
%               even = white to move, odd = black to move
%
% Backward compatibility:
%   If second input is +1/-1, it is converted to counter 0/1.
%
% Piece codes used by this KRK project:
%   10  = white king
%    5  = white rook
%  -10  = black king
%    0  = empty square
function x = encoder(chessboard, turnOrCounter)
    % Basic input validation so downstream functions can assume shape/type.
    if ~isequal(size(chessboard), [8, 8])
        error('Wrong size board: expected 8x8.');
    end

    if ~isscalar(turnOrCounter)
        error('turnOrCounter must be a scalar.');
    end

    % Convert legacy +/-1 turn into new counter convention.
    if turnOrCounter == 1
        counter = 0; % white to move
    elseif turnOrCounter == -1
        counter = 1; % black to move
    else
        if turnOrCounter < 0 || floor(turnOrCounter) ~= turnOrCounter
            error('Counter must be a nonnegative integer (even=white, odd=black).');
        end
        counter = turnOrCounter;
    end

    % Store board in the same orientation expected by reshape(... )'
    % used in solver/helper functions.
    x = chessboard';
    x = x(:);

    % Append move counter.
    x = [x; counter];
end
