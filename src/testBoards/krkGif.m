% Simulate KRK play by repeatedly selecting the minimax-best child and
% writing each board frame to a GIF.
%
% Usage:
%   result = krkGif(cb, turnOrCounter, searchDepth, maxPlies, gifFilename, frameDelay)
%
% Inputs:
%   cb          - 8x8 board matrix (10 white king, 5 white rook, -10 black king).
%   turnOrCounter - recommended: nonnegative move counter
%                   even = white to move, odd = black to move
%                   legacy +1/-1 also accepted by encoder
%   searchDepth - minimax depth in plies (>=1).
%   maxPlies    - maximum plies to simulate.
%   gifFilename - output GIF path, e.g., 'krk_sim.gif'.
%   frameDelay  - delay per frame in seconds.
%
% Output:
%   result struct with fields:
%     finalState, history, costs, endedBy, pliesPlayed, gifFilename
function result = krkGif(cb, turnOrCounter, searchDepth, maxPlies, gifFilename, frameDelay)
    % ----------------------------
    % Default argument handling
    % ----------------------------
    if nargin < 6
        frameDelay = 0.6;
    end
    if nargin < 5 || isempty(gifFilename)
        gifFilename = 'krk_sim.gif';
    end
    if nargin < 4 || isempty(maxPlies)
        maxPlies = 60;
    end
    if nargin < 3 || isempty(searchDepth)
        searchDepth = 3;
    end

    % ----------------------------
    % Input validation
    % ----------------------------
    if ~isequal(size(cb), [8, 8])
        error('cb must be 8x8.');
    end
    if ~isscalar(turnOrCounter)
        error('turnOrCounter must be scalar.');
    end
    if searchDepth < 1 || floor(searchDepth) ~= searchDepth
        error('searchDepth must be a positive integer.');
    end
    if maxPlies < 1 || floor(maxPlies) ~= maxPlies
        error('maxPlies must be a positive integer.');
    end

    % Ensure helper/solver paths are available when called directly.
    thisFileDir = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(thisFileDir);
    addpath(fullfile(projectRoot, 'solver'));
    addpath(fullfile(projectRoot, 'helper'));

    % Initialize root state and bookkeeping arrays.
    x = encoder(cb, turnOrCounter);
    history = x;
    costs = cost(x);
    endedBy = 'maxPlies';

    % Offscreen figure: renders cleanly while avoiding UI popups.
    fig = figure('Name', 'KRK GIF Generator', 'Color', 'w', 'Visible', 'off');

    for ply = 0:maxPlies
        % Decode current state for display/annotation.
        boardNow = reshape(x(1:64), 8, 8)';
        if mod(x(65), 2) == 0
            turnNow = 1;
        else
            turnNow = -1;
        end
        mateNow = isCheckmate(x, true);
        J = cost(x);

        % Draw current frame.
        clf(fig);
        plotter(boardNow, sprintf('ply %d | turn=%d | ctr=%d | cost=%.2f | mate=%d', ply, turnNow, x(65), J, mateNow));
        drawnow;

        % Capture frame and append to GIF.
        frame = getframe(fig);
        [im, map] = rgb2ind(frame2im(frame), 256);
        if ply == 0
            imwrite(im, map, gifFilename, 'gif', 'LoopCount', inf, 'DelayTime', frameDelay);
        else
            imwrite(im, map, gifFilename, 'gif', 'WriteMode', 'append', 'DelayTime', frameDelay);
        end

        % Stop if mate reached.
        if mateNow
            endedBy = 'checkmate';
            break;
        end

        % Stop if ply budget reached.
        if ply == maxPlies
            endedBy = 'maxPlies';
            break;
        end

        % Choose next state using minimax.
        [bestState, ~, ~, ~, ~] = minimaxBestMove(x, searchDepth);
        if isempty(bestState)
            % No legal move from current node.
            endedBy = 'noMoves';
            break;
        end

        % Advance simulation and record trace.
        x = bestState;
        history(:, end + 1) = x;
        costs(end + 1) = cost(x);
    end

    % Cleanup render figure.
    close(fig);

    % Package outputs for downstream analysis.
    result = struct();
    result.finalState = x;
    result.history = history;
    result.costs = costs;
    result.endedBy = endedBy;
    result.pliesPlayed = size(history, 2) - 1;
    result.gifFilename = gifFilename;
end
