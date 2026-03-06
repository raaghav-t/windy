% Encode an 8x8 chessboard into a 65x1 state vector.
% Entries 1:64 are board squares, entry 65 is turn.
function x = encoder(chessboard, turn)
    if ~isequal(size(chessboard), [8, 8])
        error('Wrong size board: expected 8x8.');
    end

    if turn ~= -1 && turn ~= 1
        error('Turn must be -1 or 1.');
    end

    x = chessboard';
    x = x(:);
    x = [x; turn];
end
