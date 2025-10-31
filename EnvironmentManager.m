clear; close all; clc;
addpath(genpath('Environment'));
addpath(genpath('UR3'));


%% Rotate Helper Function
function rotate(name, transform)
n = name;
t = transform;
vertices = get(n,'Vertices'); %getting the vertices from the ply model
transformedVertices = [vertices,ones(size(vertices,1),1)] * t';
set(n,'Vertices',transformedVertices(:,1:3));
end

hold on;
axis equal;
grid on;
axis on;
eye(3);
camlight;


%% Room Setup
%Concrete from canvas
surf([-4, -4; 4, 4], [-2, 3; -2, 3], [-0.5, -0.5; -0.5, -0.5],'CData',imread('Environment\concrete.jpg'),'FaceColor','texturemap');


%% TABLE SETUP
table_height = 0.5;
table_width = 2.1;
table_depth = 1.4;

% Table 1
table1_pos = [-table_width/2, 0.7, -0.5];
robot_table1 = PlaceObject('tableBrown2.1x1.4x0.5m.ply', table1_pos);
rotate(robot_table1, trotz(pi));


% Table 2
table2_pos = [-table_width/2, -0.7, -0.5];
robot_table2 = PlaceObject('tableBrown2.1x1.4x0.5m.ply', table2_pos);
rotate(robot_table2, trotz(pi));

% Table 3
table3_pos = [table_width/2, 0.7, -0.5];
robot_table3 = PlaceObject('tableBrown2.1x1.4x0.5m.ply', table3_pos);
rotate(robot_table3, trotz(pi));

% Table 4
table4_pos = [table_width/2, -0.7, -0.5];
robot_table4 = PlaceObject('tableBrown2.1x1.4x0.5m.ply', table4_pos);
rotate(robot_table4, trotz(pi));

%% Human Placement
human1_pos = [-3, 0, -0.5];
human1 = PlaceObject('Environment\personMaleCasual.ply', human1_pos);

%% Barriers
% Place barriers around the tables
barrier_positions = [
    0, -1.5, -.5;
    -1.5, -1.5, -.5;
    1.5, -1.5, -.5
    0, 1.5, -.5;
    -1.5, 1.5, -.5;
    1.5, 1.5, -.5
    ];
for i = 1 :size (barrier_positions,1)
    PlaceObject('Environment\barrier1.5x0.2x1m.ply', barrier_positions(i,:));
end

barrier_positions2 = [
    0.75,2.2,-0.5;
    -0.75, 2.2, -.5;
    0.75, -2.2, -.5
    -0.75, -2.2, -.5;];

for i = 1 :size (barrier_positions2,1)
    barrier = PlaceObject('barrier1.5x0.2x1m.ply', barrier_positions2(i,:));
    rotate(barrier, trotz(pi/2));
end
%% Fire Extinguisher
fireextinguisher_pos = [-1.2,-2.3,0];
fireextinguisher = PlaceObject('fireExtinguisherElevated.ply', fireextinguisher_pos);
rotate(fireextinguisher,trotz(-pi/2));

%% Trolley

trolley_pos = [-3, -1, -0.2];
trolley = PlaceObject('TrolleyScale.ply', trolley_pos);

%% Table
table = PlaceObject('tableRound0.3x0.3x0.3m.ply', [-3, 2, -0.5]); % Place at origin
chair1 = PlaceObject('chair.ply', [-3.2, -0.5, -2.2]);
rotate(chair1, trotx(+pi/2))
chair2 = PlaceObject('chair.ply', [2, -0.5, -3.4]);
rotate(chair2, trotz(+pi/2));
rotate(chair2, troty(pi/2));

%% Baby
baby = PlaceObject('baby.ply', [-3.5, 1, -0.5]);

%% Woman
female = PlaceObject('personFemaleBusiness.ply', [2, 2, -0.5]);
rotate(female, trotz(pi/2));
%% Emergency Stop
emergencystop_pos = [1, 2.3, 0.45];
emergencyStop = PlaceObject('emergencyStopWallMounted.ply', emergencystop_pos);
rotate(emergencyStop,trotz(pi/2));

book_trolley_pos = [-2.5, -1.25, 0.4];
book_trolley = PlaceObject('redBook.ply', book_trolley_pos);

%% BOOK Crate
crate_distance = 3.0; % Distance from central table
% Robot3 Crate
bookcrate1 = PlaceObject('crate1.ply', [0, 0, 0]); % Place at origin
rotate(bookcrate1, trotz(0));
set(bookcrate1, 'Vertices', get(bookcrate1, 'Vertices') + [0,1.05,0.1]);


% % Robot4 Crate
bookcrate2 = PlaceObject('crate1.ply', [0, 0, 0]); % Place at origin
rotate(bookcrate2, trotz(-pi/2));
set(bookcrate2, 'Vertices', get(bookcrate2, 'Vertices') + [1.5,0,0.1]);


% Robot2 Shelf
bookcrate3 = PlaceObject('crate1.ply', [0, 0, 0]); % Place at origin
rotate(bookcrate3, trotz(-pi));
set(bookcrate3, 'Vertices', get(bookcrate3, 'Vertices') + [0,-1.05,0.1]);