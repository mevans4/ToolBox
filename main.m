function main()
%MAIN Entry point for the multi-robot book hand-off demonstration.

    close all; clc;

    setupPaths();
    setupFigure();

    bookConfigs = defaultBookConfigs();
    fprintf('Spawning books...\n');
    bookManager = BookManager(bookConfigs);
    bookManager.reset();
    fprintf('Book manager reset\n');
    fprintf('Setting up book positions...\n');
    bookManager.spawnBooks();
    bookManager.storeBookHandles();
    fprintf('Found %d books\n', bookManager.getBookCount());

    fprintf('Creating robots...\n');
    robots = createRobotSequence();
    for idx = 1:numel(robots)
        fprintf('%s Created.\n', robots{idx}.name);
    end

    fprintf('Starting book stacking operation...\n');
    BookPickAndPlace(robots, bookManager);
end

function setupPaths()
    addpath(genpath(fullfile(pwd,'rvctools')));
    addpath(fullfile(pwd,'@LinearUR3'));
    addpath(fullfile(pwd,'@MotomanGP4'));
    addpath(fullfile(pwd,'@KUKAkr3'));
    addpath(fullfile(pwd,'@AUBOi5'));
end

function setupFigure()
    figure('Color','w');
    axis equal;
    view(135,30);
    hold on;
    xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
    light('Position',[0 0 10],'Style','infinite');
    camlight headlight;
end

function bookConfigs = defaultBookConfigs()
    bookConfigs = struct( ...
        'label', {'Red Book','Blue Book','Green Book'}, ...
        'mesh',  {'redBook.ply','blueBook.ply','greenBook.ply'}, ...
        'startPose', { ...
            transl(0.0, -0.3, 0.75) * trotz(pi/2), ...
            transl(0.0,  0.0, 0.75) * trotz(pi/2), ...
            transl(0.0,  0.3, 0.75) * trotz(pi/2) ...
        }, ...
        'finishPose', { ...
            transl(2.9, -0.3, 0.75) * trotz(pi/2), ...
            transl(2.9,  0.0, 0.75) * trotz(pi/2), ...
            transl(2.9,  0.3, 0.75) * trotz(pi/2) ...
        } ...
    );
end

function robots = createRobotSequence()
    robotData = {
        'LinearUR3',   LinearUR3(transl(0,   0, 0)),      [0.9 0.3 0.3]
        'MotomanGP4',  MotomanGP4(transl(0.9,0, 0)),      [0.3 0.3 0.9]
        'KUKAkr3',     KUKAkr3(transl(1.8,0, 0)),         [0.3 0.9 0.3]
        'AUBOi5',      AUBOi5(transl(2.7,0, 0)),          [0.9 0.7 0.3]
        };

    robots = cell(1, size(robotData,1));
    for idx = 1:size(robotData,1)
        instance = robotData{idx,2};
        robots{idx} = struct(
            'name', robotData{idx,1}, ...
            'instance', instance, ...
            'color', robotData{idx,3}, ...
            'currentQ', [], ...
            'homeQ', [] ...
        );
    end
end
