% Main execution entry point for the multi-robot sorting cell with GUI safety controls
clear; close all; clc;

controller = WorkspaceController();
controller.launch();

% Expose controller handle for interactive use from the MATLAB base workspace
assignin('base', 'workspaceController', controller);
