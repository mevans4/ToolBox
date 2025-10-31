%% Robotics
% Lab 11 - Question 4 skeleton code

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
dt = 0.15;      % Set time step for simulation (seconds)

n = 0;  % Initialise step count to zero 
tic;    % recording simulation start time
while( toc < duration)
    
    n=n+1; % increment step count

    % read joystick
    [axes, buttons, povs] = read(joy);
       
    % -------------------------------------------------------------
    % YOUR CODE GOES HERE
    % 1 - turn joystick input into an end-effector force measurement  
    fx = axes(1);
    fy = 0;
    fz = 0;
    
    tx = 0;
    ty = axes(3);
    tz = 0;
    
    f = [fx;fy;fz;tx;ty;tz]; % combined force-torque vector (wrench)
    
    % 2 - use simple admittance scheme to convert force measurement into
    % velocity command
    Ka = diag([0.3 0.3 0.3 0.5 0.5 0.5]); % admittance gain matrix  
    dx = Ka*f; % convert wrench into end-effector velocity command
    
    % 2 - use DLS J inverse to calculate joint velocity
    J = robot.jacobe(q);
    
    lambda = 0.1;
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
      
