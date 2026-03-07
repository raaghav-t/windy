% Choose best next move from state x using depth-limited minimax search.
% White minimizes cost, black maximizes cost.
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
    if depth < 1 || floor(depth) ~= depth
        error('depth must be a positive integer.');
    end

    children = possibleMoves(x);
    nChildren = size(children, 2);

    bestState = [];
    bestValue = [];
    bestIdx = [];
    childValues = [];
    info = struct('nodes', 0, 'cacheHits', 0);

    if nChildren == 0
        return;
    end

    cache = containers.Map('KeyType', 'char', 'ValueType', 'double');
    childValues = zeros(1, nChildren);

    if x(65) == 1
        bestValue = inf;
    else
        bestValue = -inf;
    end

    for k = 1:nChildren
        [value, nodes, hits, cache] = minimaxValue(children(:, k), depth - 1, -inf, inf, cache);
        childValues(k) = value;
        info.nodes = info.nodes + nodes;
        info.cacheHits = info.cacheHits + hits;

        if x(65) == 1
            if value < bestValue
                bestValue = value;
                bestIdx = k;
            end
        else
            if value > bestValue
                bestValue = value;
                bestIdx = k;
            end
        end
    end

    bestState = children(:, bestIdx);
end

function [value, nodes, cacheHits, cache] = minimaxValue(x, depth, alpha, beta, cache)
    nodes = 1;
    cacheHits = 0;

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
    
    children = possibleMoves(x);
    if isempty(children)
        value = cost(x);
        cache(key) = value;
        return;
    end

    % Move ordering: try promising moves first to improve alpha-beta pruning.
    orderedIdx = orderMoves(children, x(65));
    children = children(:, orderedIdx);

    if x(65) == 1
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
            if beta <= alpha
                break;
            end
        end
    else
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
            if beta <= alpha
                break;
            end
        end
    end

    cache(key) = value;
end

function key = stateKey(x, depth)
    key = sprintf('%d|', [depth; x(:)]);
end

function idx = orderMoves(children, turnAtNode)
    n = size(children, 2);
    scores = zeros(1, n);
    for k = 1:n
        scores(k) = cost(children(:, k));
    end

    if turnAtNode == 1
        % White to move at this node: minimizing player.
        [~, idx] = sort(scores, 'ascend');
    else
        % Black to move at this node: maximizing player.
        [~, idx] = sort(scores, 'descend');
    end
end
