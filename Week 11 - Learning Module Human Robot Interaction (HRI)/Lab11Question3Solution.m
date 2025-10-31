%% Robotics
% Updated syntax and tested for V10 compatibility (Jan 2023)
% NOTE: Joystick mappings are done for a PS4 controller
% NOTE: dt increased from 0.15 to 0.3 to reduce warnings
% Lab 11 - Question 1 solution

%% setup joystick
id = 1; % Note: may need to be changed if multiple joysticks present
joy = vrjoystick(id);
caps(joy) % display joystick information


%% Set up robot
mdl_puma560;                    % Load Puma560
robot = p560;                   % Create copy called 'robot'
robot.tool = transl(0.1,0,0);   % Define tool frame on end-effector


%% Start "real-time" simulation
q = qn;                 % Set initial robot configuration 'q'

HF = figure(1);         % Initialise figure to display robot
robot.plot(q);          % Plot robot in initial configuration
robot.delay = 0.001;    % Set smaller delay when animating
set(HF,'Position',[0.1 0.1 0.8 0.8]);

duration = 300;  % Set duration of the simulation (seconds)
dt = 0.3;      % Set time step for simulation (seconds)

n = 0;  % Initialise step count to zero 
tic;    % recording simulation start time
while( toc < duration)
    
    n=n+1; % increment step count

    % read joystick
    [axes, buttons, povs] = read(joy);
       
    % -------------------------------------------------------------
    % YOUR CODE GOES HERE
    % 1 - turn joystick input into an end-effector velocity command
    Kv = 0.3; % linear velocity gain
    Kw = 0.8; % angular velocity gain
    
    % Note: The below axes and buttons are mapped for a PS4 Controller
    % They may not be the same mapping for other controllers and so will 
    % need to be changed.
    % Map Linear Velocity
    vx = Kv*axes(1); % Left Thumbstick L(-) R(+)
    vy = -Kv*axes(2); % Left Thumbstick U(+) D(-)
    vz = Kv*(buttons(5)-buttons(7));    % Btn 5 = L1, Btn 7 = L2

    % Map Angular Velocity
    wx = Kw*axes(3);    % Right Thumbstick L(-) R(+)
    wy = Kw*axes(6);    % Right Thumbstick U(-) D(+)
    wz = Kw*(buttons(6)-buttons(8));    % Btn 6 = R1, Btn 8 = R2
    
    dx = [vx;vy;vz;wx;wy;wz]; % combined velocity vector
    
    % 2 - use DLS J inverse to calculate joint velocity
    lambda = 0.5;
    J = robot.jacob0(q);
    Jinv_dls = inv((J'*J)+lambda^2*eye(6))*J';
    dq = Jinv_dls*dx;
    
    % 3 - apply joint velocity to step robot joint angles 
    q = q + dq'*dt;
      
    % -------------------------------------------------------------
    
    % Update plot
    robot.animate(q);  
    
    % wait until loop time elapsed
    if (toc > dt*n)
        warning('Loop %i took too much time - consider increating dt',n);
    end
    while (toc < dt*n); % wait until loop time (dt) has elapsed 
    end
end


      
