% PLOTTER
% -------
% Draw KRK board as checkerboard with custom piece markers/colors.
%
% Accepted input:
%   - 8x8 board matrix, or
%   - encoded state vector (first 64 entries are board)
%
% Marker style:
%   white king -> light green star
%   white rook -> light green square
%   black king -> dark blue star
function plotter(stateOrBoard, titleText)
    % Optional title.
    if nargin < 2
        titleText = 'KRK Position';
    end

    % Normalize input to 8x8 board.
    if isvector(stateOrBoard) && numel(stateOrBoard) >= 64
        board = reshape(stateOrBoard(1:64), 8, 8)';
    elseif isequal(size(stateOrBoard), [8, 8])
        board = stateOrBoard;
    else
        error('Input must be an 8x8 board or a 65x1 encoded state.');
    end

    % Build black/white checker pattern using parity.
    checker = zeros(8, 8);
    for r = 1:8
        for c = 1:8
            checker(r, c) = mod(r + c, 2);
        end
    end

    % Draw board background.
    imagesc(1:8, 1:8, checker);
    axis equal;
    axis([0.5 8.5 0.5 8.5]);
    set(gca, 'YDir', 'reverse');
    set(gca, 'XTick', 1:8, 'YTick', 1:8);
    grid on;
    colormap([1 1 1; 0 0 0]);
    hold on;

    % Find piece coordinates.
    [rowW, colW] = find(board == 10, 1);
    [rowR, colR] = find(board == 5, 1);
    [rowB, colB] = find(board == -10, 1);

    % Visual palette requested for this project.
    lightGreen = [0.55, 0.9, 0.55];
    darkBlue = [0.05, 0.2, 0.55];

    % Draw white king.
    if ~isempty(rowW)
        plot(colW, rowW, '*', 'Color', lightGreen, 'MarkerSize', 14, 'LineWidth', 2);
    end

    % Draw white rook.
    if ~isempty(rowR)
        plot(colR, rowR, 's', ...
            'MarkerEdgeColor', lightGreen, ...
            'MarkerFaceColor', lightGreen, ...
            'MarkerSize', 10, ...
            'LineWidth', 1.5);
    end

    % Draw black king.
    if ~isempty(rowB)
        plot(colB, rowB, '*', 'Color', darkBlue, 'MarkerSize', 14, 'LineWidth', 2);
    end

    % Add title and release plotting state.
    title(titleText, 'Interpreter', 'none');
    hold off;
end
