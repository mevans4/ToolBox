function Lab1Starter()
%Lab1Starter The 1st lab starter to create, plot and multiply transforms
%   ○ Create a "New" function (no arguments) not a script or class (yet)
%   ○ Clear and close all 
%   ○ Sectioning and Running a section of code (ctrl + enter)
%   ○ Make sure Robotics Toolbox is started, you will need to specify the path to the startup_rvc.m on your device, for example: run('E:\PersonalSVN\Teaching\Robotics\MatlabToolboxUpdate-Summer22-23\SummerRobotics\Project 1 - Robotics Toolbox Integration\Combined UTS PC V10 Toolbox\rvctools\rvctools\startup_rvc.m');
%   ○ Creating and plotting a 2D transform (x,y and orientation)
%   ○ Semicolon to mute output
%   ○ Creating 2nd transform with a different colour (hold on)
%   ○ Multiplying 2nd transforms together to create a 3rd
%   ○ Multiplying a transform by its inverse to get identity
%   ○ Axis options (size, equal, grid)
%   ○ Iterate in a "for" loop and play with moving transforms (try and delete tr_h)
%   ○ One frame in another frame's 

%% PART 1: Creating and plotting a 2D transform

%% Clear & close
close all;
clc

%% Transform 1
T1 = SE2(1, 2, 30*pi/180)
T1_h = trplot2(T1, 'frame', '1', 'color', 'b');

%% Transform 2
T2 = SE2(2, 1, 0)
hold on
T2_h = trplot2(T2, 'frame', '2', 'color', 'r');

%% Transform 3 is T1*T2
T3 = T1 * T2
T3_h =trplot2(T3, 'frame', '3', 'color', 'g');

%% Axis
axis([0 5 0 5]);
axis equal;
grid on;

%% Move Transform 2
for i=90:-0.5:0
    T1 = SE2(1, 2, i*pi/180)
    delete(T1_h);
    T1_h = trplot2(T1, 'frame', '1', 'color', 'b');

%     T2 = SE2(i, 1, 0)
%     delete(T2_h);
%     T2_h = trplot2(T2, 'frame', '2', 'color', 'r');

    T3 = T1*T2
    delete(T3_h);
    T3_h =trplot2(T3, 'frame', '3', 'color', 'g');
    drawnow();
    pause(0.01);
end

%% PART 2: One frame in another frame's (roughly based on Canvas module 1.2)
close all;
clear all;
clc;
hold on;

T_0A = SE2(0,0,0); % For simplicity let's assume that the frame A is at the origin, but it doesn't need to be
trplot2(T_0A, 'frame', 'T_A', 'color', 'r');

T_AB = T_0A * SE2(1,1,-45*pi/180);
T_0B = T_0A * T_AB;
trplot2(T_0B, 'frame', 'T_B', 'color', 'b');

T_AC = SE2(3,-1,80*pi/180);
T_0C = T_0A * T_AC;
trplot2(T_0C, 'frame', 'T_C', 'color', 'g');

T_BD = SE2(1,1,45*pi/180);
T_0D = T_0A * T_AB * T_BD;
trplot2(T_0D, 'frame', 'T_D', 'color', 'y');

axis equal;
grid on;

%%  If we wanted to determine the transform from T_CD
T_CD = inv(T_0C) * T_0D

% We can proove that this worked by transforming T_0C by T_CD to be T_0D 
tranimate2(T_0C, T_0C * T_CD);

% Note T_0C * T_CD is approximately equal to T_0D, i.e. it is very close
% (less than eps). The difference is due to the way the inverse inv(T_0C)
% is previously calculated.
diffValue = (T_0C * T_CD) - T_0D
diffValue < eps % Check that all parts of the diff matrix are less than the floating point error, eps
