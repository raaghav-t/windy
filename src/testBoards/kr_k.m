% KRK test harness
% Edit only `cb` and `turn` below, then run this script.
%
% Piece encoding:
%   10  = white king
%    5  = white rook
%  -10  = black king
%    0  = empty square
%
% Turn encoding:
%    1  = white to move
%   -1  = black to move

clear;
clc;

% Add project source folders so this script can call solver/helper functions.
thisFileDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(thisFileDir);
addpath(fullfile(projectRoot, 'solver'));
addpath(fullfile(projectRoot, 'helper'));

%% Edit position here
cb = [0 0 0 10 0 0 0 5;
      0 0 0  0 0 0 0 0;
      0 0 0  0 0 0 0 0;
      0 0 0  0 0 0 0 0;
      0 0 0  0 0 0 0 0;
      0 0 0  0 0 0 0 0;
      0 0 0  0 0 0 0 0;
      0 0 0 -10 0 0 0 0];

turn = 1;

%% Quick validation
if ~isequal(size(cb), [8, 8])
    error('Board must be 8x8.');
end
if nnz(cb == 10) ~= 1 || nnz(cb == 5) ~= 1 || nnz(cb == -10) ~= 1
    error('Board must contain exactly one white king (10), one white rook (5), and one black king (-10).');
end
if turn ~= 1 && turn ~= -1
    error('turn must be 1 (white) or -1 (black).');
end

%% Evaluate current state
x = encoder(cb, turn);
fprintf('Current position:\n');
disp(cb);
fprintf('Turn: %d (1=white, -1=black)\n', turn);

spaceForBlack = oxygenBKing(x);
distKings = distance(x);
J = cost(x);
mate = isCheckmate(x);
nextStates = possibleMoves(x);

fprintf('\nState metrics:\n');
fprintf('  oxygenBKing: %d\n', spaceForBlack);
fprintf('  distance:    %d\n', distKings);
fprintf('  cost:        %.4f\n', J);
fprintf('  isCheckmate: %d\n', mate);
fprintf('  #moves:      %d\n', size(nextStates, 2));

%% Plot current board
figure('Name', 'KRK Current Position');
plotter(cb, sprintf('Current Position (turn=%d)', turn));

%% Evaluate immediate children by cost
if isempty(nextStates)
    fprintf('\nNo legal next moves from this position.\n');
else
    childCosts = zeros(1, size(nextStates, 2));
    childMate = false(1, size(nextStates, 2));
    for k = 1:size(nextStates, 2)
        childCosts(k) = cost(nextStates(:, k));
        childMate(k) = isCheckmate(nextStates(:, k));
    end

    [~, idx] = sort(childCosts, 'ascend');

    fprintf('\nTop 5 lowest-cost child states:\n');
    topN = min(5, numel(idx));
    for i = 1:topN
        j = idx(i);
        fprintf('  child %d: cost=%.4f, isCheckmate=%d\n', j, childCosts(j), childMate(j));
    end

    fprintf('\nTop 5 highest-cost child states:\n');
    [~, idxDesc] = sort(childCosts, 'descend');
    topN = min(5, numel(idxDesc));
    for i = 1:topN
        j = idxDesc(i);
        fprintf('  child %d: cost=%.4f, isCheckmate=%d\n', j, childCosts(j), childMate(j));
    end

    fprintf('\nBest child by side to move:\n');
    if turn == 1
        bestIdx = idx(1); % white minimizes
    else
        bestIdx = idxDesc(1); % black maximizes
    end
    fprintf('  child %d chosen\n', bestIdx);
    disp(reshape(nextStates(1:64, bestIdx), 8, 8)');
    fprintf('  next turn: %d\n', nextStates(65, bestIdx));

    % Plot a few forecasted states: best three by side to move.
    if turn == 1
        forecastOrder = idx;
    else
        forecastOrder = idxDesc;
    end
    nForecast = min(3, numel(forecastOrder));
    figure('Name', 'KRK Forecast States');
    for i = 1:nForecast
        childIdx = forecastOrder(i);
        subplot(1, nForecast, i);
        plotter(nextStates(:, childIdx), ...
            sprintf('child %d | cost=%.3f', childIdx, childCosts(childIdx)));
    end
end
