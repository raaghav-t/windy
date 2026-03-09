% KR_K TEST HARNESS
% -----------------
% Interactive debugging script for KRK solver components.
%
% Primary workflow:
%   1) edit `cb`, `turn`, `searchDepth`
%   2) run this script
%   3) inspect console metrics + plots
%
% Piece encoding:
%   10  = white king
%    5  = white rook
%  -10  = black king
%    0  = empty square
%
% Turn/counter encoding (recommended):
%   moveCounter even  -> white to move
%   moveCounter odd   -> black to move
%
% Backward compatibility:
%   turnOrCounter = 1 or -1 is also accepted by encoder.

clear;
clc;

% Resolve project-relative paths so this script can be run from anywhere.
thisFileDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(thisFileDir);
addpath(fullfile(projectRoot, 'solver'));
addpath(fullfile(projectRoot, 'helper'));

%% Edit position here
cb = [0 0 0 0 0 0 0 0;
      0 0 0  10 0 0 0 0;
      0 0 0  0 0 0 0 5;
      0 0 0  0 0 0 0 0;
      0 0 0  0 0 0 0 0;
      0 0 0  0 0 0 0 0 ;
      0 0 0  0 0 0 0 0;
      0 0 0 -10 0 0 0 0];

turnOrCounter = 0;
searchDepth = 4; % forecast plies for minimax

%% Quick validation
% Keep tests explicit and friendly before calling solver.
if ~isequal(size(cb), [8, 8])
    error('Board must be 8x8.');
end
if nnz(cb == 10) ~= 1 || nnz(cb == 5) ~= 1 || nnz(cb == -10) ~= 1
    error('Board must contain exactly one white king (10), one white rook (5), and one black king (-10).');
end
if ~isscalar(turnOrCounter)
    error('turnOrCounter must be scalar.');
end
if searchDepth < 1 || floor(searchDepth) ~= searchDepth
    error('searchDepth must be a positive integer.');
end

%% Evaluate current state
% Encode board into shared state format and compute root diagnostics.
x = encoder(cb, turnOrCounter);
fprintf('Current position:\n');
disp(cb);
if mod(x(65), 2) == 0
    rootTurn = 1;
else
    rootTurn = -1;
end
fprintf('Turn: %d (1=white, -1=black)\n', rootTurn);
fprintf('Counter x(65): %d\n', x(65));

spaceForBlack = oxygenBKing(x);
distKings = distance(x);
J = cost(x);
mate = isCheckmate(x);
mateStrictTurn = isCheckmate(x, true);
nextStates = possibleMoves(x);

fprintf('\nState metrics:\n');
fprintf('  oxygenBKing: %d\n', spaceForBlack);
fprintf('  distance:    %d\n', distKings);
fprintf('  cost:        %.4f\n', J);
fprintf('  isCheckmate: %d\n', mate);
fprintf('  isCheckmate (strict turn): %d\n', mateStrictTurn);
fprintf('  #moves:      %d\n', size(nextStates, 2));
fprintf('  searchDepth: %d ply\n', searchDepth);

if mate && ~mateStrictTurn
    fprintf('  note: board is checkmate pattern but turn is set to white (1).\n');
end

%% Depth-limited minimax from root
% Evaluate children by deeper lookahead, not just immediate heuristic.
[bestDeepState, bestDeepValue, bestDeepIdx, childDeepValues, searchInfo] = minimaxBestMove(x, searchDepth);
if isempty(bestDeepState)
    fprintf('\nMinimax: no legal moves from root.\n');
else
    fprintf('\nMinimax (%d-ply):\n', searchDepth);
    fprintf('  best child index: %d\n', bestDeepIdx);
    fprintf('  best minimax value: %.4f\n', bestDeepValue);
    fprintf('  expanded nodes: %d\n', searchInfo.nodes);
    fprintf('  cache hits: %d\n', searchInfo.cacheHits);
    fprintf('  chosen move board:\n');
    disp(reshape(bestDeepState(1:64), 8, 8)');

    if rootTurn == 1
        [~, deepOrder] = sort(childDeepValues, 'ascend');
    else
        [~, deepOrder] = sort(childDeepValues, 'descend');
    end

    fprintf('\nTop 5 children by minimax value:\n');
    topN = min(5, numel(deepOrder));
    for i = 1:topN
        j = deepOrder(i);
        fprintf('  child %d: minimax=%.4f\n', j, childDeepValues(j));
    end
end

%% Plot current board
% Visual snapshot of root position.
figure('Name', 'KRK Current Position');
plotter(cb, sprintf('Current Position (turn=%d, counter=%d)', rootTurn, x(65)));

%% Evaluate immediate children by cost
% One-ply view (for debugging heuristics independently of deep search).
if isempty(nextStates)
    fprintf('\nNo legal next moves from this position.\n');
else
    childCosts = zeros(1, size(nextStates, 2));
    childMate = false(1, size(nextStates, 2));
    for k = 1:size(nextStates, 2)
        childCosts(k) = cost(nextStates(:, k));
        childMate(k) = isCheckmate(nextStates(:, k), true);
    end

    % Immediate best-to-worst ranking by static cost.
    [~, idx] = sort(childCosts, 'ascend');
    mateIdx = find(childMate);

    if ~isempty(mateIdx)
        fprintf('\nMating child states found:\n');
        for ii = 1:numel(mateIdx)
            j = mateIdx(ii);
            fprintf('  child %d: cost=%.4f\n', j, childCosts(j));
        end
    end

    fprintf('\nTop 5 lowest-cost child states:\n');
    topN = min(5, numel(idx));
    for i = 1:topN
        j = idx(i);
        fprintf('  child %d: cost=%.4f, isCheckmate=%d\n', j, childCosts(j), childMate(j));
    end

    % Worst-to-best for contrast/debugging.
    fprintf('\nTop 5 highest-cost child states:\n');
    [~, idxDesc] = sort(childCosts, 'descend');
    topN = min(5, numel(idxDesc));
    for i = 1:topN
        j = idxDesc(i);
        fprintf('  child %d: cost=%.4f, isCheckmate=%d\n', j, childCosts(j), childMate(j));
    end

    % Baseline 1-ply decision (not deep minimax).
    fprintf('\nBest child by side to move:\n');
    if rootTurn == 1
        bestIdx = idx(1); % white minimizes
    else
        bestIdx = idxDesc(1); % black maximizes
    end
    fprintf('  child %d chosen\n', bestIdx);
    disp(reshape(nextStates(1:64, bestIdx), 8, 8)');
    fprintf('  next turn: %d\n', nextStates(65, bestIdx));

    % Plot a few forecasted states.
    % Prefer deep minimax ordering when available; fallback to one-ply cost.
    if ~isempty(bestDeepState)
        if rootTurn == 1
            [~, forecastOrder] = sort(childDeepValues, 'ascend');
        else
            [~, forecastOrder] = sort(childDeepValues, 'descend');
        end
    else
        if rootTurn == 1
            forecastOrder = idx;
        else
            forecastOrder = idxDesc;
        end
    end
    nForecast = min(3, numel(forecastOrder));
    figure('Name', 'KRK Forecast States');
    for i = 1:nForecast
        childIdx = forecastOrder(i);
        subplot(1, nForecast, i);
        if ~isempty(bestDeepState)
            % Label with deep minimax value.
            plotter(nextStates(:, childIdx), ...
                sprintf('child %d | minimax=%.3f', childIdx, childDeepValues(childIdx)));
        else
            % Label with immediate heuristic cost.
            plotter(nextStates(:, childIdx), ...
                sprintf('child %d | cost=%.3f', childIdx, childCosts(childIdx)));
        end
    end
end
