% MINIMAXCACHERESET
% -----------------
% Reset persistent transposition data used by minimaxBestMove.
%
% Call this if you changed evaluation logic (cost/checkmate rules) and want
% to avoid reusing stale cached values from older runs.
function minimaxCacheReset()
    clear minimaxBestMove
end
