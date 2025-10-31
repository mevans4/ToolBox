% Main execution script with GUI
clear; close all; clc;

% Setup environment
EnvironmentManager;

% Spawn books (these are added to the existing environment)
fprintf('Spawning books...\n');
BookSpawner.spawnBooks();
BookSpawner.drawBookStartMarkers();

% Create robots
fprintf('Creating robots...\n');
robots = RobotFactory.createAllRobots();

% Initialize book manager
bookManager = BookManager();

%UR3 Code
BookPickAndPlace(robots{1}, bookManager);

%Motoman
MotomanPickAndPlace(robots{2}, bookManager, [4, 3]);

%KUKA
KukaPickAndPlace(robots{3}, bookManager, [])



