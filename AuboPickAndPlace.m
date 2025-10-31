function delivered = AuboPickAndPlace(robot, bookManager, colorName, safetyController)
%AUBOPICKANDPLACE Coordinate AUBO i5 colour-specific book delivery.

    if nargin < 4
        safetyController = [];
    end

    delivered = 0;
    fprintf('Starting AUBO i5 delivery for %s books...\n', char(colorName));

    homeQ = getAuboHomePosition(robot);
    moveAuboToHomePosition(robot, homeQ, safetyController);

    while true
        entry = bookManager.popBookFromColorStack(colorName);
        if isempty(entry)
            break;
        end

        targetPos = bookManager.getRobotDeliveryPosition('Aubo');
        [success, finalCenter] = ColorStackPickAndPlace(robot, entry, targetPos, homeQ, safetyController);
        if ~success
            fprintf('AUBO failed to place book - returning entry to stack.\n');
            bookManager.pushBookBack(colorName, entry);
            break;
        end

        delivered = delivered + 1;
        bookManager.registerDeliveryPlacement('Aubo', colorName, finalCenter, entry.handle);
        fprintf('AUBO placed %s book %d at [%.3f, %.3f, %.3f].\n', ...
            char(colorName), delivered, finalCenter(1), finalCenter(2), finalCenter(3));

        moveAuboToHomePosition(robot, homeQ, safetyController);
    end

    fprintf('AUBO delivery complete: %d books handled.\n', delivered);
end

function homeQ = getAuboHomePosition(robot)
    if isprop(robot, 'homeQ') && ~isempty(robot.homeQ)
        homeQ = robot.homeQ;
    else
        homeQ = robot.initialJointAngles;
    end
    homeQ = homeQ(:)';
end

function moveAuboToHomePosition(robot, homeQ, safetyController)
    if nargin < 3
        safetyController = [];
    end

    qCurrent = robot.model.getpos();
    if isempty(qCurrent)
        qCurrent = homeQ;
    end

    if max(abs(qCurrent - homeQ)) < 1e-3
        return;
    end

    steps = 40;
    qTraj = jtraj(qCurrent, homeQ, steps);
    for i = 1:steps
        qStep = qTraj(i, :);
        if ~isempty(safetyController)
            if ~safetyController.ensureMotionPermitted(robot, qStep)
                return;
            end
        end
        robot.model.animate(qStep);
        if ~isempty(safetyController)
            safetyController.notifyRobotPose(robot, qStep);
        end
        drawnow('limitrate');
        pause(0.01);
    end
end
