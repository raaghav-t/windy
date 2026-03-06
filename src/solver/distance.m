% King distance on the board (Chebyshev metric).
function dist = distance(x)
    board = reshape(x(1:64), 8, 8)';

    [rowW, colW] = find(board == 10, 1);
    [rowB, colB] = find(board == -10, 1);

    if isempty(rowW) || isempty(rowB)
        error('Board must contain both kings.');
    end

    dist = max(abs(rowW - rowB), abs(colW - colB));
end
