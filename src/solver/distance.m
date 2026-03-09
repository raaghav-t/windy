% DISTANCE
% --------
% Return Chebyshev distance between the two kings.
%
% Chebyshev distance is appropriate for king movement because kings move
% one square in any direction:
%   dist = max(|dr|, |dc|)
function dist = distance(x)
    % Decode 65x1 state vector back into 8x8 board.
    board = reshape(x(1:64), 8, 8)';

    % Locate white and black kings.
    [rowW, colW] = find(board == 10, 1);
    [rowB, colB] = find(board == -10, 1);

    % A valid position should always include both kings.
    if isempty(rowW) || isempty(rowB)
        error('Board must contain both kings.');
    end

    % King-to-king distance in king-move metric.
    dist = max(abs(rowW - rowB), abs(colW - colB));
end
