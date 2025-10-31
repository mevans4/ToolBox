function bookPassingDemo()
% bookPassingDemo  Coordinate four robots to pass books between start and end poses.
%
%   The demo instantiates the LinearUR3, MotomanGP4, KUKAkr3 and AUBOi5
%   robots and has them pass red, blue and green books along a straight
%   line.  Start and end poses for each book are defined near the top of
%   this function.  Adjusting those poses is all that is required to move
%   the start or end locations – as long as the poses remain within the
%   robots' workspaces the robots will automatically compute new inverse
%   kinematics solutions for the hand-off.

% Copyright (c) 2024

%% Environment setup ---------------------------------------------------
close all; clc;

% Ensure the robot model folders and RVCTools are on the MATLAB path.
addpath(genpath(fullfile(pwd,'rvctools')));
addpath(fullfile(pwd,'@LinearUR3'));
addpath(fullfile(pwd,'@MotomanGP4'));
addpath(fullfile(pwd,'@KUKAkr3'));
addpath(fullfile(pwd,'@AUBOi5'));

figure('Color','w');
axis equal;
view(135,30);
hold on;
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
light('Position',[0 0 10],'Style','infinite');
camlight headlight;

%% Robot instances ------------------------------------------------------
robotSequence = {
    struct('name','LinearUR3', 'instance', LinearUR3(transl(0, 0, 0)),      'color',[0.9 0.3 0.3])
    struct('name','MotomanGP4','instance', MotomanGP4(transl(0.9, 0, 0.0)), 'color',[0.3 0.3 0.9])
    struct('name','KUKAkr3',   'instance', KUKAkr3(transl(1.8, 0, 0.0)),    'color',[0.3 0.9 0.3])
    struct('name','AUBOi5',    'instance', AUBOi5(transl(2.7, 0, 0.0)),     'color',[0.9 0.7 0.3])
};

for rIdx = 1:numel(robotSequence)
    robot = robotSequence{rIdx}.instance.model;
    if isempty(robotSequence{rIdx}.instance.homeQ)
        qMid = mean(robot.qlim,2)';
    else
        qMid = robotSequence{rIdx}.instance.homeQ;
    end
    robotSequence{rIdx}.currentQ = qMid;
    robot.animate(qMid);
end

%% Book configuration --------------------------------------------------
books = {
    struct('label','Red Book',  'mesh','redBook.ply',  'start', transl(0.0, -0.3, 0.75) * trotz(pi/2), 'finish', transl(2.9, -0.3, 0.75) * trotz(pi/2))
    struct('label','Blue Book', 'mesh','blueBook.ply', 'start', transl(0.0,  0.0, 0.75) * trotz(pi/2), 'finish', transl(2.9,  0.0, 0.75) * trotz(pi/2))
    struct('label','Green Book','mesh','greenBook.ply','start', transl(0.0,  0.3, 0.75) * trotz(pi/2), 'finish', transl(2.9,  0.3, 0.75) * trotz(pi/2))
};

bookMeshes = cellfun(@(b) loadBookMesh(b.mesh), books, 'UniformOutput', false);

%% Execute the book hand-off sequence ----------------------------------
for bIdx = 1:numel(books)
    bookInfo = books{bIdx};
    meshInfo = bookMeshes{bIdx};

    fprintf('Passing %s\n', bookInfo.label);

    % Place book at the starting pose.
    bookPose = bookInfo.start;
    bookHandle = plotBook(meshInfo, bookPose);

    % Compute the hand-off poses along the line between the start and finish.
    stationTransforms = computeStations(bookInfo.start, bookInfo.finish, numel(robotSequence)+1);

    % Each robot performs a pick (station i) and place (station i+1).
    for rIdx = 1:numel(robotSequence)
        robotState = robotSequence{rIdx};
        robotModel = robotState.instance.model;

        pickupPose = stationTransforms{rIdx};
        dropPose   = stationTransforms{rIdx+1};

        qPickup = solveIK(robotModel, pickupPose, robotState.currentQ);
        robotState.currentQ = moveRobot(robotModel, robotState.currentQ, qPickup, false, bookHandle, meshInfo);

        % Attach the book to the robot and move to the drop pose.
        qDrop = solveIK(robotModel, dropPose, robotState.currentQ);
        robotState.currentQ = moveRobot(robotModel, robotState.currentQ, qDrop, true, bookHandle, meshInfo);

        % Detach the book at the drop pose for the next robot.
        bookPose = dropPose;
        updateBookPose(bookHandle, meshInfo, bookPose);

        robotSequence{rIdx}.currentQ = robotState.currentQ;
    end

    % Leave the book at its final destination before moving to the next one.
    updateBookPose(bookHandle, meshInfo, bookInfo.finish);
end

end

%% Helper functions -----------------------------------------------------

function meshData = loadBookMesh(filename)
    [faces, vertices, plyData] = plyread(filename, 'tri');

    try
        vertexColours = [plyData.vertex.red, plyData.vertex.green, plyData.vertex.blue] / 255;
    catch
        vertexColours = repmat([0.5, 0.5, 0.5], size(vertices, 1), 1);
    end

    meshData.faces = faces;
    meshData.vertices = vertices;
    meshData.vertexColours = vertexColours;
end

function h = plotBook(meshData, pose)
    transformed = applyTransform(meshData.vertices, pose);
    h = trisurf(meshData.faces, transformed(:,1), transformed(:,2), transformed(:,3), ...
        'FaceVertexCData', meshData.vertexColours, 'EdgeColor','none', 'FaceLighting','gouraud');
end

function updateBookPose(handle, meshData, pose)
    transformed = applyTransform(meshData.vertices, pose);
    set(handle, 'Vertices', transformed);
end

function transformed = applyTransform(vertices, pose)
    T = poseToMatrix(pose);
    pts = [vertices, ones(size(vertices,1),1)] * T';
    transformed = pts(:,1:3);
end

function T = poseToMatrix(pose)
    if isa(pose, 'RTBPose')
        T = pose.T;
    elseif isa(pose, 'SE3')
        T = pose.T;
    elseif isnumeric(pose)
        T = pose;
    else
        error('Unsupported pose type: %s', class(pose));
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

function qFinal = moveRobot(robotModel, qStart, qTarget, carryBook, bookHandle, meshData)
    steps = 50;
    trajectory = jtraj(qStart, qTarget, steps);

    for k = 1:steps
        robotModel.animate(trajectory(k,:));
        if carryBook
            eePose = robotModel.fkine(trajectory(k,:));
            updateBookPose(bookHandle, meshData, eePose);
        end
        drawnow();
    end

    qFinal = qTarget;
end

