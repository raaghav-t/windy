% MINIMAXBESTMOVE
% ---------------
% Pick best immediate child from state x using depth-limited minimax search.
%
% Roles:
%   white (turn = 1) minimizes cost
%   black (turn = -1) maximizes cost
%
% The function also returns value estimates for every root child so callers
% can inspect/rank alternatives.
%
% Inputs:
%   x     - 65x1 encoded state.
%   depth - forecast depth in plies (>=1).
%
% Outputs:
%   bestState   - chosen child state (65x1), or [] if no legal moves.
%   bestValue   - minimax value of chosen child.
%   bestIdx     - index into possibleMoves(x) columns.
%   childValues - minimax value for each child.
%   info        - struct with fields: nodes, cacheHits.
function [bestState, bestValue, bestIdx, childValues, info] = minimaxBestMove(x, depth)
    % Depth is measured in plies (half-moves).
    if depth < 1 || floor(depth) ~= depth
        error('depth must be a positive integer.');
    end

    % Generate all legal immediate children.
    children = possibleMoves(x);
    nChildren = size(children, 2);

    % Initialize outputs to "empty result" defaults.
    bestState = [];
    bestValue = [];
    bestIdx = [];
    childValues = [];
    info = struct('nodes', 0, 'cacheHits', 0);

    % No legal move from root.
    if nChildren == 0
        return;
    end

    % Tactical shortcut:
    % if white can deliver immediate mate, choose it directly.
    if x(65) == 1
        mateChildren = false(1, nChildren);
        for k = 1:nChildren
            mateChildren(k) = isCheckmate(children(:, k), true);
        end
        if any(mateChildren)
            bestIdx = find(mateChildren, 1, 'first');
            bestState = children(:, bestIdx);
            bestValue = -1e6;
            childValues = inf(1, nChildren);
            childValues(mateChildren) = -1e6;
            info = struct('nodes', 0, 'cacheHits', 0);
            return;
        end
    end

    % Transposition cache:
    % key = (depth, full state vector), value = minimax value.
    cache = containers.Map('KeyType', 'char', 'ValueType', 'double');
    childValues = zeros(1, nChildren);

    % Initialize root best value based on side to move.
    if x(65) == 1
        bestValue = inf;
    else
        bestValue = -inf;
    end

    % Evaluate each child by searching remaining depth-1 plies.
    for k = 1:nChildren
        [value, nodes, hits, cache] = minimaxValue(children(:, k), depth - 1, -inf, inf, cache);
        childValues(k) = value;
        info.nodes = info.nodes + nodes;
        info.cacheHits = info.cacheHits + hits;

        % Root move selection:
        % white picks minimum, black picks maximum.
        if x(65) == 1
            if value < bestValue
                bestValue = value;
                bestIdx = k;
            elseif value == bestValue && cost(children(:, k)) < cost(children(:, bestIdx))
                % Tie-break toward better immediate heuristic.
                bestIdx = k;
            end
        else
            if value > bestValue
                bestValue = value;
                bestIdx = k;
            elseif value == bestValue && cost(children(:, k)) > cost(children(:, bestIdx))
                % Tie-break toward better immediate heuristic.
                bestIdx = k;
            end
        end
    end

    % Return selected child state itself.
    bestState = children(:, bestIdx);
end

% Recursive alpha-beta minimax.
function [value, nodes, cacheHits, cache] = minimaxValue(x, depth, alpha, beta, cache)
    % Count this node.
    nodes = 1;
    cacheHits = 0;

    % Use cached value if this (state, depth) was already solved.
    key = stateKey(x, depth);
    if isKey(cache, key)
        value = cache(key);
        cacheHits = 1;
        return;
    end

    % Leaf evaluation cutoff before move generation is essential for speed.
    if depth == 0
        value = cost(x);
        cache(key) = value;
        return;
    end

    % Expand children only for non-leaf nodes.
    children = possibleMoves(x);
    if isempty(children)
        % No legal moves: treat as terminal and evaluate board.
        value = cost(x);
        cache(key) = value;
        return;
    end

    % Move ordering: try promising moves first to improve alpha-beta pruning.
    orderedIdx = orderMoves(children, x(65));
    children = children(:, orderedIdx);

    if x(65) == 1
        % White node: minimizing.
        value = inf;
        for k = 1:size(children, 2)
            [childValue, childNodes, childHits, cache] = minimaxValue(children(:, k), depth - 1, alpha, beta, cache);
            nodes = nodes + childNodes;
            cacheHits = cacheHits + childHits;

            if childValue < value
                value = childValue;
            end

            if value < beta
                beta = value;
            end
            % Alpha-beta cutoff.
            if beta <= alpha
                break;
            end
        end
    else
        % Black node: maximizing.
        value = -inf;
        for k = 1:size(children, 2)
            [childValue, childNodes, childHits, cache] = minimaxValue(children(:, k), depth - 1, alpha, beta, cache);
            nodes = nodes + childNodes;
            cacheHits = cacheHits + childHits;

            if childValue > value
                value = childValue;
            end

            if value > alpha
                alpha = value;
            end
            % Alpha-beta cutoff.
            if beta <= alpha
                break;
            end
        end
    end

    % Save solved value for future transposition hits.
    cache(key) = value;
end

% Build deterministic cache key from depth and full state vector.
function key = stateKey(x, depth)
    key = sprintf('%d|', [depth; x(:)]);
end

% Move ordering helper to improve alpha-beta pruning efficiency.
function idx = orderMoves(children, turnAtNode)
    n = size(children, 2);
    scores = zeros(1, n);

    % Cheap heuristic ordering via static cost function.
    for k = 1:n
        scores(k) = cost(children(:, k));
    end

    if turnAtNode == 1
        % White to move: likely best children are lower-cost first.
        [~, idx] = sort(scores, 'ascend');
    else
        % Black to move: likely best children are higher-cost first.
        [~, idx] = sort(scores, 'descend');
    end
end
