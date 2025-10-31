function delivered = KukaPickAndPlace(robot, bookManager, colorName, safetyController)
%KUKAPICKANDPLACE Coordinate KUKA KR3 colour-specific delivery.

    if nargin < 4
        safetyController = [];
    end

    delivered = 0;
    fprintf('Starting KUKA KR3 delivery for %s books...\n', char(colorName));

    homeQ = getKukaHomePosition(robot);
    moveKukaToHomePosition(robot, homeQ, safetyController);

    while true
        [entry, stackInfo] = bookManager.popBookFromColorStack(colorName);
        if isempty(entry)
            if delivered == 0
                info = bookManager.getColorStackInfo(colorName);
                fprintf('KUKA stack for %s is empty at [%.3f, %.3f, %.3f].\n', ...
                    char(colorName), info.base(1), info.base(2), info.base(3));
            end
            break;
        end

        fprintf('KUKA retrieving %s book from stack base [%.3f, %.3f, %.3f] level %d.\n', ...
            char(colorName), stackInfo.base(1), stackInfo.base(2), stackInfo.base(3), stackInfo.level);

        targetPos = bookManager.getRobotDeliveryPosition('Kuka');
        [success, finalCenter] = ColorStackPickAndPlace(robot, entry, targetPos, homeQ, safetyController);
        if ~success
            fprintf('KUKA failed to place book - returning entry to stack.\n');
            bookManager.pushBookBack(colorName, entry);
            break;
        end

        delivered = delivered + 1;
        bookManager.registerDeliveryPlacement('Kuka', colorName, finalCenter, entry.handle);
        fprintf('KUKA placed %s book %d at [%.3f, %.3f, %.3f].\n', ...
            char(colorName), delivered, finalCenter(1), finalCenter(2), finalCenter(3));

        moveKukaToHomePosition(robot, homeQ, safetyController);
    end

    fprintf('KUKA delivery complete: %d books handled.\n', delivered);
end

function homeQ = getKukaHomePosition(robot)
    if isprop(robot, 'homeQ') && ~isempty(robot.homeQ)
        homeQ = robot.homeQ;
    else
        homeQ = zeros(1, robot.model.n);
    end
end

function moveKukaToHomePosition(robot, homeQ, safetyController)
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

    steps = 35;
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
