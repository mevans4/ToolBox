%% Robotics
% Lab 4 - Questions 1: 3-link plannar draw a line then circle
% Updated syntax and tested for V10 compatibility (Jan 2023)
function [  ] = Lab4Solution_Question1( )

clf

% Make a 3DOF model
L1 = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi])
L2 = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi])
L3 = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi])        
robot = SerialLink([L1 L2 L3],'name','myRobot');                     


% Rotate the base around the Y axis so the Z axis faces downways
robot.base = troty(pi);

% Make workspace big except inthe negative z
workspace = [-4 4 -4 4 -0.05 2];                                       % Set the size of the workspace when drawing the robot
        
scale = 0.5;
        
q = zeros(1,3);                                                     % Create a vector of initial joint angles
        
robot.plot(q,'workspace',workspace,'scale',scale);                  % Plot the robot
        
robot.teach;
disp('Press enter to continue');
pause;

% Get a solution for the end effector at [-0.75,-0.5,0]. Note that from
% teach you can see that there is no way to affect the Z, roll or pitch values no matter
% what you choose. Since the pen is considered to be the Z axis then we
% don't care about the yaw angle (if pen where the Z axis rotating it
% doesn't affect the result, so we just mask that out

% UPDATE: ikine function now has different syntax when entering
% arguments into the function call. The argument must be prefaced by
% its argument name. E.g. Initial Q Guess = 'q0', q & Mask = 'mask', m.
newQ = robot.ikine(transl(-0.75,-0.5,0), 'q0', q, 'mask', [1,1,0,0,0,0]);

% Now plot this new joint state
robot.plot(newQ)

% Add a plotting trail. Alternatively, close the figure and run: robot.plot(newQ,'trail','-')
rh = findobj('Tag', robot.name); ud = rh.UserData; hold on; ud.trail = plot(0,0,'-'); set(rh,'UserData',ud);

% Check how close it got to the goal transform of transl(-0.75,-0.5,0)
% UPDATE: fkine function now returns an SE3 object. To obtain the Transform
% Matrix, access the variable in the object 'T' with '.T'.
robot.fkine(newQ).T

% Now go through a loop using the previous joint as the guess to draw a
% line from [-0.75,-0.5,0] to [-0.75,0.5,0]
for y = -0.5:0.05:0.5
    % UPDATE: ikine function now has different syntax when entering
    % arguments into the function call. The argument must be prefaced by
    % its argument name. E.g. Initial Q Guess = 'q0', q & Mask = 'mask', m.
    newQ = robot.ikine(transl(-0.75,y,0), 'q0', newQ, 'mask', [1,1,0,0,0,0]);%,'alpha',0.01);
    robot.animate(newQ);
    drawnow();
end
disp('Press enter to continue');
pause;

%% Now use the same robot and draw a circle around the robot at a distance of 0.5
hold on;
plot(-0.5,0,'r.')
for circleHalf = 1:2
    for x = -0.5:0.05:0.5
        if circleHalf == 1
            y = sqrt(0.5^2-x^2);
        else
            x = -x;
            y = -sqrt(0.5^2-x^2);
        end
        plot(x,y,'r.');
        % UPDATE: ikine function now has different syntax when entering
        % arguments into the function call. The argument must be prefaced by
        % its argument name. E.g. Initial Q Guess = 'q0', q & Mask = 'mask', m.
        newQ = robot.ikine(transl(x,y,0), 'q0', newQ, 'mask', [1,1,0,0,0,0]);%,'alpha',0.01);
        robot.animate(newQ);
        drawnow();
    end
end

end

