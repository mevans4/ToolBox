function KukaPickAndPlace(robot, bookManager, colorSequence)
    % KukaPickAndPlace - KUKA KR3 R540 book sorting routine
    % Uses shared bookManager to locate books and create colour-specific stacks

    if nargin < 3 || isempty(colorSequence)
        colorSequence = {'green', 'green', 'blue', 'blue', 'red', 'red'};
    end

    fprintf('Starting KUKA KR3 pick and place routine...\n');

    homeQ = getKukaHomePosition(robot);
    fprintf('Moving KUKA to initial home position\n');
    moveKukaToHomePosition(robot, homeQ);

    % Reacquire the latest book data from the environment
    bookManager.reset();
    bookManager.storeBookHandles();

    totalBooks = length(bookManager.originalBookHandles);
    if totalBooks == 0
        fprintf('No books available for KUKA.\n');
        return;
    end

    fprintf('KUKA detected %d books. Preparing sequence...\n', totalBooks);

    bookOrder = determineKukaBookOrder(bookManager, colorSequence);

    processed = 0;
    for idx = 1:length(bookOrder)
        bookIndex = bookOrder(idx);
        if bookIndex < 1 || bookIndex > totalBooks
            continue;
        end

        bookInfo = bookManager.originalBookHandles{bookIndex};
        if isempty(bookInfo) || ~isfield(bookInfo, 'handle') || isempty(bookInfo.handle)
            fprintf('Skipping invalid book entry at index %d.\n', bookIndex);
            continue;
        end

        [bookHandle, originalVerts, bookPos, topSurfacePos, bookColor] = refreshBookInfo(bookInfo);
        fprintf('\n=== KUKA Processing %s book (%d/%d) ===\n', bookColor, idx, length(bookOrder));
        fprintf('Book located at [%.3f, %.3f, %.3f]\n', bookPos(1), bookPos(2), bookPos(3));

        targetStackPos = bookManager.getColorStackPosition(bookColor);
        fprintf('Target stack position for %s: [%.3f, %.3f, %.3f]\n', bookColor, ...
            targetStackPos(1), targetStackPos(2), targetStackPos(3));

        success = executeKukaPickPlace(robot, bookHandle, originalVerts, bookPos, ...
            topSurfacePos, targetStackPos, homeQ);

        if success
            processed = processed + 1;
            bookManager.originalBookHandles{bookIndex}.position = targetStackPos;
            bookManager.originalBookHandles{bookIndex}.topSurfacePosition = [
                targetStackPos(1), targetStackPos(2), targetStackPos(3) + bookManager.bookHeights];
        else
            fprintf('Failed to place %s book at target stack.\n', bookColor);
        end

        fprintf('Returning KUKA to home position after book %d\n', idx);
        moveKukaToHomePosition(robot, homeQ);
    end

    fprintf('\nKUKA completed %d/%d book transfers.\n', processed, length(bookOrder));
    fprintf('KUKA returning to final home position.\n');
    moveKukaToHomePosition(robot, homeQ);
end

function bookOrder = determineKukaBookOrder(bookManager, colorSequence)
    totalBooks = length(bookManager.originalBookHandles);
    usedMask = false(1, totalBooks);
    bookOrder = [];

    colorSequence = ensureCellArray(colorSequence);

    for i = 1:length(colorSequence)
        entry = colorSequence{i};
        if isnumeric(entry)
            colorIdx = entry;
            colorName = kukaColorIndexToString(colorIdx);
        else
            colorName = lower(char(entry));
            colorIdx = kukaColorStringToIndex(colorName);
        end
        if isnan(colorIdx) || colorIdx < 1 || colorIdx > 3
            warning('Unknown colour request "%s" for KUKA sequence. Skipping.', colorName);
            continue;
        end

        matchIdx = findMatchingBook(bookManager, colorIdx, usedMask);
        if ~isempty(matchIdx)
            bookOrder(end+1) = matchIdx; %#ok<AGROW>
            usedMask(matchIdx) = true;
        end
    end

    for bookIdx = 1:totalBooks
        if ~usedMask(bookIdx)
            bookOrder(end+1) = bookIdx; %#ok<AGROW>
        end
    end
end

function matchIdx = findMatchingBook(bookManager, colorIdx, usedMask)
    matchIdx = [];
    for i = 1:length(bookManager.originalBookHandles)
        if usedMask(i)
            continue;
        end
        bookInfo = bookManager.originalBookHandles{i};
        if isempty(bookInfo)
            continue;
        end
        if isfield(bookInfo, 'colorIndex') && bookInfo.colorIndex == colorIdx
            matchIdx = i;
            return;
        end
        % Fallback to colour string if colour index missing
        if ~isfield(bookInfo, 'colorIndex') && isfield(bookInfo, 'color')
            if kukaColorStringToIndex(bookInfo.color) == colorIdx
                matchIdx = i;
                return;
            end
        end
    end
end

function arr = ensureCellArray(value)
    if iscell(value)
        arr = value;
    elseif isnumeric(value)
        arr = num2cell(value);
    else
        arr = {value};
    end
end

function [bookHandle, originalVerts, bookPos, topSurfacePos, colorName] = refreshBookInfo(bookInfo)
    bookHandle = bookInfo.handle;
    originalVerts = get(bookHandle, 'Vertices');

    bookPos = mean(originalVerts, 1);
    maxVerts = max(originalVerts, [], 1);
    topSurfacePos = [bookPos(1), bookPos(2), maxVerts(3)];

    if isfield(bookInfo, 'colorIndex')
        colorName = lower(kukaColorIndexToString(bookInfo.colorIndex));
    elseif isfield(bookInfo, 'color')
        colorName = lower(char(bookInfo.color));
    else
        colorName = 'unknown';
    end
end

function success = executeKukaPickPlace(robot, bookHandle, originalVerts, bookPos, topSurfacePos, targetPos, homeQ)
    pickConfig = homeQ;

    approachHeight = 0.12;
    approachPos = [bookPos(1), bookPos(2), topSurfacePos(3) + approachHeight];
    fprintf('Moving to KUKA approach position: [%.3f, %.3f, %.3f]\n', approachPos(1), approachPos(2), approachPos(3));
    if ~moveRobotWithConfig(robot, approachPos, pickConfig)
        success = false;
        return;
    end
    pause(0.2);

    pickOffset = 0.01;
    pickPos = [bookPos(1), bookPos(2), topSurfacePos(3) + pickOffset];
    fprintf('Moving to KUKA pick position: [%.3f, %.3f, %.3f]\n', pickPos(1), pickPos(2), pickPos(3));
    if ~moveRobotWithConfig(robot, pickPos, pickConfig)
        success = false;
        return;
    end
    pause(0.2);

    currentQ = robot.model.getpos();
    currentEePose = robot.model.fkine(currentQ);
    currentEePos = currentEePose(1:3, 4)';

    currentBookCenter = mean(originalVerts, 1);
    bookOffset = currentBookCenter - currentEePos;
    fprintf('Calculated KUKA book offset: [%.3f, %.3f, %.3f]\n', bookOffset(1), bookOffset(2), bookOffset(3));

    bookData.handle = bookHandle;
    bookData.offset = bookOffset;
    bookData.originalVerts = originalVerts;
    bookData.targetPos = targetPos;

    liftHeight = 0.15;
    liftPos = [bookPos(1), bookPos(2), topSurfacePos(3) + liftHeight];
    fprintf('Lifting book to: [%.3f, %.3f, %.3f]\n', liftPos(1), liftPos(2), liftPos(3));
    if ~moveRobotWithBookPerfectPlacement(robot, liftPos, bookHandle, bookData, pickConfig)
        success = false;
        return;
    end
    pause(0.2);

    targetEePos = targetPos - bookOffset;
    targetApproachHeight = 0.12;
    targetApproach = [targetEePos(1), targetEePos(2), targetEePos(3) + targetApproachHeight];
    fprintf('Moving to placement approach: [%.3f, %.3f, %.3f]\n', targetApproach(1), targetApproach(2), targetApproach(3));
    if ~moveRobotWithBookPerfectPlacement(robot, targetApproach, bookHandle, bookData, pickConfig)
        success = false;
        return;
    end
    pause(0.2);

    fprintf('Placing book at: [%.3f, %.3f, %.3f]\n', targetEePos(1), targetEePos(2), targetEePos(3));
    if ~moveRobotWithBookPerfectPlacement(robot, targetEePos, bookHandle, bookData, pickConfig)
        success = false;
        return;
    end

    pause(0.3);
    success = true;
end

function colorIdx = kukaColorStringToIndex(colorName)
    switch lower(char(colorName))
        case {'green', 'g'}
            colorIdx = 1;
        case {'blue', 'b'}
            colorIdx = 2;
        case {'red', 'r'}
            colorIdx = 3;
        otherwise
            colorIdx = NaN;
    end
end

function colorName = kukaColorIndexToString(colorIdx)
    switch colorIdx
        case 1
            colorName = 'green';
        case 2
            colorName = 'blue';
        case 3
            colorName = 'red';
        otherwise
            colorName = 'unknown';
    end
end

function homeQ = getKukaHomePosition(robot)
    if isprop(robot, 'homeQ') && ~isempty(robot.homeQ)
        homeQ = robot.homeQ;
    else
        homeQ = zeros(1, robot.model.n);
    end
    fprintf('KUKA home configuration: [');
    fprintf('%.2f ', homeQ);
    fprintf(']\n');
end

function moveKukaToHomePosition(robot, homeQ)
    qCurrent = robot.model.getpos();
    if isempty(qCurrent)
        qCurrent = homeQ;
    end

    if max(abs(qCurrent - homeQ)) < 1e-3
        fprintf('KUKA already at home position.\n');
        return;
    end

    steps = 25;
    qTraj = jtraj(qCurrent, homeQ, steps);
    for i = 1:steps
        robot.model.animate(qTraj(i, :));
        drawnow();
        pause(0.01);
    end
    fprintf('KUKA reached home position.\n');
end

function success = moveRobotWithConfig(robot, targetPosition, referenceConfig)
    steps = 25;
    qCurrent = robot.model.getpos();
    if isempty(qCurrent)
        qCurrent = referenceConfig;
    end

    fprintf('  Moving to [%.3f, %.3f, %.3f] using KUKA configuration reference\n', ...
        targetPosition(1), targetPosition(2), targetPosition(3));

    targetTransform = transl(targetPosition) * trotx(pi) * trotz(-pi/2);
    qTarget = robot.model.ikcon(targetTransform, referenceConfig);

    if any(isnan(qTarget))
        fprintf('  IK failed with reference config, retrying from current position.\n');
        qTarget = robot.model.ikcon(targetTransform, qCurrent);
    end

    if any(isnan(qTarget))
        fprintf('  IK failed completely for point [%.3f, %.3f, %.3f].\n', ...
            targetPosition(1), targetPosition(2), targetPosition(3));
        success = false;
        return;
    end

    qTraj = jtraj(qCurrent, qTarget, steps);
    for i = 1:steps
        robot.model.animate(qTraj(i, :));
        drawnow();
        pause(0.01);
    end

    success = true;
end

function success = moveRobotWithBookPerfectPlacement(robot, targetPosition, bookHandle, bookData, referenceConfig)
    steps = 25;
    qCurrent = robot.model.getpos();
    if isempty(qCurrent)
        qCurrent = referenceConfig;
    end

    fprintf('  Moving with book to [%.3f, %.3f, %.3f]\n', targetPosition(1), targetPosition(2), targetPosition(3));

    targetTransform = transl(targetPosition) * trotx(pi) * trotz(-pi/2);
    qTarget = robot.model.ikcon(targetTransform, referenceConfig);

    if any(isnan(qTarget))
        fprintf('  IK failed with reference config, trying current position.\n');
        qTarget = robot.model.ikcon(targetTransform, qCurrent);
    end

    if any(isnan(qTarget))
        fprintf('  IK failed again, using current configuration as fallback.\n');
        qTarget = qCurrent;
    end

    qTraj = jtraj(qCurrent, qTarget, steps);
    initialEePose = robot.model.fkine(qCurrent);

    for i = 1:steps
        q = qTraj(i, :);
        robot.model.animate(q);

        try
            currentEePose = robot.model.fkine(q);
            relativeTransform = currentEePose / initialEePose;

            currentVerts = bookData.originalVerts;
            originalCenter = mean(currentVerts, 1);
            centeredVerts = currentVerts - originalCenter;
            rotatedVerts = (relativeTransform(1:3, 1:3) * centeredVerts')';
            calculatedBookPos = currentEePose(1:3, 4)' + bookData.offset;
            newVerts = rotatedVerts + calculatedBookPos;
            set(bookHandle, 'Vertices', newVerts);
        catch ME
            fprintf('  WARNING: Failed to rotate book geometry (%s). Applying translation only.\n', ME.message);
            currentEePose = robot.model.fkine(q);
            eePos = currentEePose(1:3, 4)';
            translation = eePos + bookData.offset - mean(bookData.originalVerts, 1);
            set(bookHandle, 'Vertices', bookData.originalVerts + translation);
        end

        drawnow();
        pause(0.01);
    end

    if isfield(bookData, 'targetPos')
        finalVerts = get(bookHandle, 'Vertices');
        currentCenter = mean(finalVerts, 1);
        targetCenter = bookData.targetPos;
        positionError = targetCenter - currentCenter;
        if norm(positionError) > 0.001
            fprintf('  Final KUKA position adjustment: [%.3f, %.3f, %.3f]\n', ...
                positionError(1), positionError(2), positionError(3));
            set(bookHandle, 'Vertices', finalVerts + positionError);
        end
    end

    success = true;
end
