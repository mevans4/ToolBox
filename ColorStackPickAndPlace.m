function [success, finalCenter] = ColorStackPickAndPlace(robot, bookEntry, targetPos, referenceConfig, safetyController)
%COLORSTACKPICKANDPLACE Safely transfers a book from a colour stack to a target
%   robot            - robot instance from RobotFactory
%   bookEntry        - struct returned from BookManager.popBookFromColorStack
%   targetPos        - desired centre position for the book at the destination
%   referenceConfig  - nominal joint configuration used for IK initialisation
%   safetyController - SafetyController instance for collision and stop handling
%
%   Returns success flag and the final placed centre position.

    if nargin < 5
        safetyController = [];
    end

    success = false;
    finalCenter = [NaN, NaN, NaN];

    if isempty(bookEntry) || ~isfield(bookEntry, 'handle')
        warning('ColorStackPickAndPlace:InvalidEntry', 'Book entry missing handle information.');
        return;
    end

    bookHandle = bookEntry.handle;
    if isempty(bookHandle) || ~isgraphics(bookHandle)
        warning('ColorStackPickAndPlace:InvalidGraphics', 'Book graphics handle is invalid.');
        return;
    end

    currentVerts = get(bookHandle, 'Vertices');
    bookCenter = mean(currentVerts, 1);
    maxVerts = max(currentVerts, [], 1);
    topSurface = [bookCenter(1), bookCenter(2), maxVerts(3)];

    approachHeight = 0.12;
    pickHeight = 0.01;
    liftHeight = 0.18;

    approachPos = [bookCenter(1), bookCenter(2), topSurface(3) + approachHeight];
    pickPos = [bookCenter(1), bookCenter(2), topSurface(3) + pickHeight];

    if ~SafeMotion.moveRobotWithConfig(robot, approachPos, referenceConfig, safetyController)
        warning('ColorStackPickAndPlace:ApproachFailed', 'Failed to reach approach pose for book.');
        return;
    end

    if ~SafeMotion.moveRobotWithConfig(robot, pickPos, referenceConfig, safetyController)
        warning('ColorStackPickAndPlace:PickFailed', 'Failed to reach pick pose for book.');
        return;
    end

    currentQ = robot.model.getpos();
    try
        eePose = robot.model.fkine(currentQ);
    catch
        eePose = robot.model.fkineUTS(currentQ);
    end
    eePos = transl(eePose)';

    bookOffset = bookCenter - eePos;

    bookData = struct();
    bookData.offset = bookOffset;
    bookData.originalVerts = currentVerts;
    bookData.targetPos = targetPos;

    liftPos = [bookCenter(1), bookCenter(2), topSurface(3) + liftHeight];
    if ~SafeMotion.moveRobotWithBookPerfectPlacement(robot, liftPos, bookHandle, bookData, referenceConfig, safetyController)
        warning('ColorStackPickAndPlace:LiftFailed', 'Failed to lift book safely.');
        return;
    end

    targetEePos = targetPos - bookOffset;
    targetApproach = [targetEePos(1), targetEePos(2), targetEePos(3) + approachHeight];

    if ~SafeMotion.moveRobotWithBookPerfectPlacement(robot, targetApproach, bookHandle, bookData, referenceConfig, safetyController)
        warning('ColorStackPickAndPlace:ApproachTargetFailed', 'Failed to reach target approach pose.');
        return;
    end

    if ~SafeMotion.moveRobotWithBookPerfectPlacement(robot, targetEePos, bookHandle, bookData, referenceConfig, safetyController)
        warning('ColorStackPickAndPlace:PlaceFailed', 'Failed to place book at destination.');
        return;
    end

    finalVerts = get(bookHandle, 'Vertices');
    finalCenter = mean(finalVerts, 1);

    SafeMotion.moveRobotWithConfig(robot, targetApproach, referenceConfig, safetyController);

    success = true;
end
