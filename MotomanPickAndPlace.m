function delivered = MotomanPickAndPlace(robot, bookManager, colorName, safetyController)
%MOTOMANPICKANDPLACE Coordinate Motoman GP4 colour-specific delivery.
%   robot            - Motoman robot instance
%   bookManager      - shared BookManager instance
%   colorName        - colour stack to service (e.g. 'blue')
%   safetyController - SafetyController reference

    if nargin < 4
        safetyController = [];
    end

    delivered = 0;
    fprintf('Starting Motoman GP4 colour delivery for %s books...\n', char(colorName));

    homeQ = getMotomanHomePosition(robot);
    moveMotomanToHomePosition(robot, homeQ, safetyController);

    while true
        [entry, stackInfo] = bookManager.popBookFromColorStack(colorName);
        if isempty(entry)
            if delivered == 0
                info = bookManager.getColorStackInfo(colorName);
                fprintf('Motoman found no %s books at stack [%.3f, %.3f, %.3f].\n', ...
                    char(colorName), info.base(1), info.base(2), info.base(3));
            end
            break;
        end

        fprintf('Motoman picking %s book from stack base [%.3f, %.3f, %.3f] level %d.\n', ...
            char(colorName), stackInfo.base(1), stackInfo.base(2), stackInfo.base(3), stackInfo.level);

        targetPos = bookManager.getRobotDeliveryPosition('Motoman');
        [success, finalCenter] = ColorStackPickAndPlace(robot, entry, targetPos, homeQ, safetyController);
        if ~success
            fprintf('Motoman failed to place book - returning entry to stack.\n');
            bookManager.pushBookBack(colorName, entry);
            break;
        end

        delivered = delivered + 1;
        bookManager.registerDeliveryPlacement('Motoman', colorName, finalCenter, entry.handle);
        fprintf('Motoman delivered %s book %d to [%.3f, %.3f, %.3f].\n', ...
            char(colorName), delivered, finalCenter(1), finalCenter(2), finalCenter(3));

        moveMotomanToHomePosition(robot, homeQ, safetyController);
    end

    fprintf('Motoman delivery complete: %d books handled.\n', delivered);
end

function homeQ = getMotomanHomePosition(~)
    homeQ = [0, 0, 0, 0, 0, 0];
end

function moveMotomanToHomePosition(robot, homeQ, safetyController)
    if nargin < 3
        safetyController = [];
    end

    qCurrent = robot.model.getpos();
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
