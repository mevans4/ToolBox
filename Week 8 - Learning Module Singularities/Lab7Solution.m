%% Robotics
% Lab 7
function Lab7Solution()

close all
clc

%% Q1 Derive 3-link Jacobian and use Matlab symbolic solver

% 1.2 From the derived Jacobian equation
syms l1 l2 l3 x y phi q1 q2 q3 Jq;

x = l1*cos(q1) + l2*cos(q1+q2) + l2*cos(q1+q2+q3);
y = l1*sin(q1) + l2*sin(q1+q2) + l2*sin(q1+q2+q3);
phi = q1 + q2 + q3;

% Compute the Jacobian
Jq = [diff(x,q1),diff(x,q2),diff(x,q3) ...
    ; diff(y,q1),diff(y,q2),diff(y,q3) ...
    ; diff(phi,q1),diff(phi,q2),diff(phi,q3)];

% 1.3 Solve for the link lengths being 1
JqForLength1 = subs(subs(subs(Jq,l1,1),l2,1),l3,1)

% 1.4 Solve for all joint angles being 0. By observation x velocity is 0
subs(subs(subs(JqForLength1,q1,0),q2,0),q3,0)

% Confirm this by using the toolbox
mdl_planar3;                                                                % Load 2-Link Planar Robot
p3.jacob0([0,0,0])

%% Q2 Dealing with Singularities
close all
clc
mdl_planar2;                                                                % Load 2-Link Planar Robot
M = [1 1 zeros(1,4)];                                                       % Masking Matrix
deltaT = 0.05;                                                              % Discrete time step

minManipMeasure = 0.1;
steps = 100;
deltaTheta = 2*pi/steps;
x = [];

for i = 1:steps
    x(:,i) = [1.5*cos(deltaTheta*i) + 0.45*cos(deltaTheta*i)
              1.5*sin(deltaTheta*i) + 0.45*cos(deltaTheta*i)];
end

% Define 4x4 Transformation Matrix for desired manipulator start pose 
T = [eye(3) [x(:,1);0];zeros(1,3) 1]

% NOTE: Edited below so can be changed by setting the variable either true
% or false rather than having to comment out the lines.

% Try with either ikine or ikcon by changing the below below
useIkine = true;

% Take note of the result from using ikine in this scenario.
% What does the warning tell you about the final error?
% Is the desired pose reachable by the manipulator? If not, by what error?
% You will realise that if inputting a 4x4 Transformation Matrix to ikine
% which is out of range of the manipulator, the solver will fail to
% converge, returning no solution for joint states.
% What happens when you change the x-coordinate of the T matrix to 1.9?

% NOTE: You can force ikine to return its best calculated joint state if the
% solution is diverging by setting the option 'forceSoln'. Note that this 
% means the manipulator will NOT reach the specified transformation pose as 
% it is not the correct solution, simply the last calculated joint state
% before the solution diverged.

curDist = sqrt(T(1,4)^2 + T(2,4)^2 + T(3,4)^2)
% T(1,4) = 1.9;
% adjustDist = sqrt(T(1,4)^2 + T(2,4)^2 + T(3,4)^2)

if useIkine
    % Try with ikine
    % qMatrix = 0.2605    0.0234 (V9 Solution)
    startPose = true;
    try
        qMatrix(1,:) = p2.ikine(T, 'q0', [0 0], 'mask', M, 'forceSoln');
    catch
        disp('Ikine failed to converge - defined pose not reachable by the manipulator')
        startPose = false;
    end
else
    % Try with ikcon
    qMatrix(1,:) = p2.ikcon(T, [0 0])
end

if startPose
    m = zeros(1,steps);
    error = nan(2,steps);
    for i = 1:steps-1
        xdot = (x(:,i+1) - x(:,i))/deltaT;                                      % Calculate velocity at discrete time step
        J = p2.jacob0(qMatrix(i,:));                                            % Get the Jacobian at the current state
        J = J(1:2,:);                                                           % Take only first 2 rows
        m(:,i)= sqrt(det(J*J'));                                                % Measure of Manipulability
        if m(:,i) < minManipMeasure
            qdot = inv(J'*J + 0.01*eye(2))*J'*xdot;
        else
            qdot = inv(J) * xdot;                                               % Solve velocitities via RMRC
        end
        error(:,i) = xdot - J*qdot;
        qMatrix(i+1,:) = qMatrix(i,:) + deltaT * qdot';                         % Update next joint state
    end

    figure(1)
    set(gcf,'units','normalized','outerposition',[0 0 1 1])
    p2.plot(qMatrix,'trail','r-')                                               % Animate the robot
    figure(2)
    plot(m,'k','LineWidth',1);                                                  % Plot the Manipulability
    title('Manipulability of 2-Link Planar')
    ylabel('Manipulability')
    xlabel('Step')
    figure(3)
    plot(error','Linewidth',1)
    ylabel('Error (m/s)')
    xlabel('Step')
    legend('x-velocity','y-velocity');
end

%% Q3
% Download the file from Canvas.
% This was originally created from ros computer '138.25.213.85' (which is not online anymore) with a kinect-type camera connected
% try rosinit('138.25.213.85');end
% depthRawSub = rossubscriber('/camera/depth/image_raw'); % Depends upon the camera in use (refer to instructions)
% rgbRawSub = rossubscriber('/camera/rgb/image_raw'); % Depends upon the camera in use (refer to instructions)
% pause(2);
% depthImg = readImage(depthRawSub.LatestMessage);
% rgbImg = readImage(rgbRawSub.LatestMessage);

% To store the data
% maxImages = 20;
% depthImageData = repmat(depthImg,1,1,maxImages);
% rgbImageData = repmat(rgbImg,1,1,1,maxImages);
% for i = 1:maxImages
%     depthImageData(:,:,i) = readImage(depthRawSub.LatestMessage);
%     rgbImageData(:,:,:,i) = readImage(rgbRawSub.LatestMessage);
%    pause(0.1);
%end
%save('imageData.mat','depthImageData','rgbImageData')

%% 3.2 (load)
load('imageData.mat');

%% 3.2 (show)
maxImages = 20;
% Show the data from the Depth and RGB images
for i = 1:maxImages
    imshow(histeq(depthImageData(:,:,i)));
    imshow(rgbImageData(:,:,:,i));
    drawnow();
    pause(0.5);
end
    
%% 3.3 
surf(histeq(depthImageData(:,:,1)));

%% 3.4
widthFOV = 58;
heightFOV = 45;
widthResolutionDegrees = widthFOV / size(depthImageData,2);
heightResolutionDegrees = heightFOV / size(depthImageData,1);

%% 3.5 (point spacing at 1m) Medium res
widthSpacing = tan(deg2rad(widthResolutionDegrees));
heightSpacing = tan(deg2rad(heightResolutionDegrees));

%% 3.6 (point spacing at 1m) High res
widthSpacing = tan(deg2rad(widthResolutionDegrees));
heightSpacing = tan(deg2rad(heightResolutionDegrees));

%% 3.7 Point Cloud
X_TO_Z = 1.114880018171494;
Y_TO_Z = 0.836160013628620;
rowCount = size(depthImageData,1);
colCount = size(depthImageData,2);
pointMillimeters = zeros(colCount*rowCount,3);
for i = 1:rowCount
    for j = 1:colCount
        x = (j /colCount -0.5) * depthImageData(i,j,1) * X_TO_Z;
        y = (0.5 -i / rowCount) * depthImageData(i,j,1) * Y_TO_Z;
        pointMillimeters((i-1) * colCount + j,:) = [x, y, depthImageData(i,j,1)];
    end
end
pointMeters = pointMillimeters / 1000;

%% 3.8 (Bonus) Eye-In-Hand
robot = SchunkUTSv2_0;
q = [0,pi/2,0,0,0,0];
robot.plot3d(q);
camlight
hold on;
plot_h = plot3(0,0,0,'.r');
for joint2Rads = pi/2 : -0.1:0
    q = [0,joint2Rads,0,0,0,0];
    tr = robot.fkine(q).T;
    transformedPoints = [tr * [pointMeters,ones(size(pointMeters,1),1)]']';
    transformedPoints = transformedPoints(:,1:3);
    plot_h.XData = transformedPoints(:,1);
    plot_h.YData = transformedPoints(:,2);
    plot_h.ZData = transformedPoints(:,3);
    robot.animate(q);
    axis equal
    drawnow();
end
%%
end

