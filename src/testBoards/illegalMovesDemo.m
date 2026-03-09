% ILLEGALMOVESDEMO
% ----------------
% Demonstrate common illegal moves in KRK and show that `possibleMoves`
% rejects them.
%
% Run:
%   run('src/testBoards/illegalMovesDemo.m')

clear;
clc;

% Resolve project-relative paths.
thisFileDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(thisFileDir);
addpath(fullfile(projectRoot, 'solver'));
addpath(fullfile(projectRoot, 'helper'));

fprintf('KRK illegal move demo\n');
fprintf('=====================\n\n');

demoKingAdjacent();
demoKingIntoRookAttack();
demoRookJumpOverKing();
demoBlackCaptureProtectedRook();
demoMoveOffBoard();

% -------------------------------------------------------------------------
function demoKingAdjacent()
    fprintf('Example 1: White king moves next to black king (illegal)\n');

    cb = zeros(8, 8);
    cb(4, 4) = 10;   % white king
    cb(4, 8) = 5;    % white rook
    cb(6, 6) = -10;  % black king
    x = encoder(cb, 0); % counter 0 => white to move

    % Attempt: white king from (4,4) to (5,5), adjacent to black king at (6,6)
    y = attemptMove(x, [4 4], [5 5], 10);
    printLegality(x, y, 'Kings cannot be adjacent after a move.');
    showBoards(cb, y, 'Illegal WK adjacent move');
end

% -------------------------------------------------------------------------
function demoKingIntoRookAttack()
    fprintf('Example 2: Black king steps into rook attack (illegal)\n');

    cb = zeros(8, 8);
    cb(2, 2) = 10;   % white king
    cb(1, 4) = 5;    % white rook
    cb(3, 4) = -10;  % black king
    x = encoder(cb, 1); % counter 1 => black to move

    % Attempt: black king from (3,4) to (2,4), still on rook file
    y = attemptMove(x, [3 4], [2 4], -10);
    printLegality(x, y, 'Black king cannot move onto a square attacked by white rook.');
    showBoards(cb, y, 'Illegal BK into attack');
end

% -------------------------------------------------------------------------
function demoRookJumpOverKing()
    fprintf('Example 3: White rook jumps over white king (illegal)\n');

    cb = zeros(8, 8);
    cb(5, 4) = 10;   % white king blocks rook path
    cb(7, 4) = 5;    % white rook
    cb(8, 8) = -10;  % black king
    x = encoder(cb, 0); % white to move

    % Attempt: rook from (7,4) to (3,4), jumping over king at (5,4)
    y = attemptMove(x, [7 4], [3 4], 5);
    printLegality(x, y, 'Rook cannot jump over pieces.');
    showBoards(cb, y, 'Illegal rook jump');
end

% -------------------------------------------------------------------------
function demoBlackCaptureProtectedRook()
    fprintf('Example 4: Black king captures protected rook (illegal)\n');

    cb = zeros(8, 8);
    cb(6, 6) = 10;   % white king protects rook
    cb(7, 7) = 5;    % white rook
    cb(8, 8) = -10;  % black king
    x = encoder(cb, 1); % black to move

    % Attempt: black king captures rook on (7,7), but square protected by WK
    y = attemptMove(x, [8 8], [7 7], -10);
    printLegality(x, y, 'Black king cannot capture a rook protected by white king.');
    showBoards(cb, y, 'Illegal capture of protected rook');
end

% -------------------------------------------------------------------------
function demoMoveOffBoard()
    fprintf('Example 5: Move off board (illegal)\n');

    cb = zeros(8, 8);
    cb(1, 1) = 10;
    cb(1, 8) = 5;
    cb(8, 8) = -10;
    x = encoder(cb, 0); % white to move

    % Attempt: white king from (1,1) to (0,1), off-board.
    y = attemptMove(x, [1 1], [0 1], 10);
    printLegality(x, y, 'Pieces cannot move outside board bounds.');
    showBoards(cb, y, 'Illegal off-board move');
end

% -------------------------------------------------------------------------
function y = attemptMove(x, fromRC, toRC, pieceCode)
    % Build attempted next state by directly editing board.
    board = reshape(x(1:64), 8, 8)';

    fromR = fromRC(1); fromC = fromRC(2);
    toR = toRC(1); toC = toRC(2);

    if fromR < 1 || fromR > 8 || fromC < 1 || fromC > 8
        y = [];
        return;
    end
    if toR < 1 || toR > 8 || toC < 1 || toC > 8
        y = []; % represent impossible board edit for off-board move
        return;
    end
    if board(fromR, fromC) ~= pieceCode
        y = [];
        return;
    end

    board(toR, toC) = pieceCode;
    board(fromR, fromC) = 0;
    y = board';
    y = y(:);
    y = [y; x(65) + 1];
end

% -------------------------------------------------------------------------
function printLegality(x, attemptedState, reason)
    legal = false;
    legalChildren = possibleMoves(x);

    if ~isempty(attemptedState)
        for k = 1:size(legalChildren, 2)
            if isequal(legalChildren(:, k), attemptedState)
                legal = true;
                break;
            end
        end
    end

    if legal
        fprintf('  Result: LEGAL (unexpected for this demo)\n\n');
    else
        fprintf('  Result: ILLEGAL (as expected)\n');
        fprintf('  Why: %s\n\n', reason);
    end
end

% -------------------------------------------------------------------------
function showBoards(beforeBoard, attemptedState, figTitleText)
    figure('Name', figTitleText);
    subplot(1, 2, 1);
    plotter(beforeBoard, 'Before');

    subplot(1, 2, 2);
    if isempty(attemptedState)
        axis off;
        title('Attempted: off-board/invalid edit');
    else
        afterBoard = reshape(attemptedState(1:64), 8, 8)';
        plotter(afterBoard, 'Attempted (illegal)');
    end
end
