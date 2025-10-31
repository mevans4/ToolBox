function BookPickAndPlace(robots, bookManager)
%BOOKPICKANDPLACE Coordinate robots to pass books sequentially.
%
%   BookPickAndPlace(robots, bookManager) takes a cell array (or struct
%   array) of robot definitions and a BookManager instance. Each robot
%   definition must contain a `name` field and an `instance` field whose
%   `model` property is an RVC SerialLink. The routine moves every robot to
%   its home pose, then iterates through the configured books to perform
%   pick-and-place hand-offs along evenly spaced stations between the start
%   and finish poses.

    if ~iscell(robots)
        robots = num2cell(robots);
    end

    if isempty(robots)
        warning('BookPickAndPlace:NoRobots', 'No robots were supplied to BookPickAndPlace.');
        return;
    end

    % Ensure we are working with mutable structs inside the cell array.
    for idx = 1:numel(robots)
        robotState = robots{idx};
        model = robotState.instance.model;

        if isempty(robotState.instance.homeQ)
            qHome = mean(model.qlim, 2)';
        else
            qHome = robotState.instance.homeQ;
        end

        robotState.currentQ = qHome;
        robotState.homeQ = qHome;
        robots{idx} = robotState;

        fprintf('%s moving to home position.\n', robotState.name);
        model.animate(qHome);
        drawnow();
    end

    bookManager.storeBookHandles();
    bookConfigs = bookManager.getBookConfigs();

    for bookIdx = 1:numel(bookConfigs)
        book = bookConfigs(bookIdx);
        meshData = bookManager.getMesh(bookIdx);
        handle = bookManager.getBookHandle(bookIdx);

        fprintf('Passing %s\n', book.label);
        bookManager.updateBookPose(handle, meshData, book.startPose);

        stationTransforms = computeStations(book.startPose, book.finishPose, numel(robots) + 1);

        for robotIdx = 1:numel(robots)
            robotState = robots{robotIdx};
            model = robotState.instance.model;

            qPickup = solveIK(model, stationTransforms{robotIdx}, robotState.currentQ);
            robotState.currentQ = moveRobot(model, robotState.currentQ, qPickup, false, bookManager, handle, meshData);

            qDrop = solveIK(model, stationTransforms{robotIdx + 1}, robotState.currentQ);
            robotState.currentQ = moveRobot(model, robotState.currentQ, qDrop, true, bookManager, handle, meshData);

            bookManager.updateBookPose(handle, meshData, stationTransforms{robotIdx + 1});
            robots{robotIdx} = robotState;
        end

        bookManager.updateBookPose(handle, meshData, book.finishPose);
    end
end

function stationTransforms = computeStations(startPose, endPose, stationCount)
    fractions = linspace(0, 1, stationCount);
    stationTransforms = cell(1, stationCount);
    for i = 1:stationCount
        stationTransforms{i} = trinterp(startPose, endPose, fractions(i));
    end
end

function qSolution = solveIK(robotModel, targetPose, qInitial)
    try
        qSolution = robotModel.ikcon(targetPose, qInitial);
    catch
        qSolution = robotModel.ikine(targetPose, 'mask', [1 1 1 1 1 1], 'q0', qInitial);
    end
end

function qFinal = moveRobot(robotModel, qStart, qTarget, carryBook, bookManager, bookHandle, meshData)
    steps = 50;
    trajectory = jtraj(qStart, qTarget, steps);

    for k = 1:steps
        robotModel.animate(trajectory(k,:));
        if carryBook
            eePose = robotModel.fkine(trajectory(k,:));
            bookManager.updateBookPose(bookHandle, meshData, eePose);
        end
        drawnow();
    end

    qFinal = qTarget;
end
