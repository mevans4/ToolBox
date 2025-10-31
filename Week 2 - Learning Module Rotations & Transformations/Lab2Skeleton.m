classdef Lab2Skeleton < handle
    properties (Constant)
        % You can define shared values or helpers here, e.g., a list of transforms.
        % This is useful if you want to cleanly reuse them in multiple questions (like in Q1 and Q3).
        %
        % Example Consider storing a list of UAV poses as a cell array so you can loop through them later. 
        % trSteps = {eye(4), ...};
    end

    methods
        function self = Lab2Skeleton()
            clf;
            clc;
            input('Press enter to begin');
            self.Question1();
            self.Question2();
            self.Question3();
            self.Question3point8();
            self.Question4();
        end
    end

    methods (Static)

%% Question 1: Animate transform (Quad copter flying)
        function Question1()
            % Question 1: Animate a UAV flying to monitor cattle
            % Use tranimate to show the UAV moving and rotating through the steps below.
            
            % Set up the figure
            clf;
            hold on;
            grid on;
            view(3);
            axis equal;
            axis([-1, 4, -1, 4, 0, 11]);

            % 1.1) Start at the origin and move up to 10m off the ground (positive Z)

            % 1.2) Rotate (roll) around the X axis by -30 degrees

            % 1.3) Move in the direction of global Y to [0, 2, 10]

            % 1.4) Roll back to level (reset orientation to identity)

            % 1.5) Rotate (pitch) around the Y axis by +30 degrees

            % 1.6) Move in the direction of global X to [2, 2, 10]

            % 1.7) Roll back to level (orientation should again be identity)

            % 1.8) Go to the ground at [2, 2, 0]

            % 1.9) Encode the above steps in a `for` loop using a list of transforms (e.g., a cell array).
            % Use 'fps' option in tranimate to control animation speed.

            % 1.10) Display RPY angles and quaternion of the UAV at each step.
            % Hint: Use tr2rpy and UnitQuaternion to convert transform to orientation formats.
            % Hint: Use the `text` command to display text in the 3D plot corner.

            % input('Finished question 1, press Enter to continue');
        end
        
%% Question 2: Plotting and moving the herd of RobotCows
        function Question2()
            clf;
            % 2.1 Create cowHerd
            % cowHerd = RobotCows();

            % 2.2 Check number of cows
            % cowHerd.cowCount

            % 2.3 Single step
            % cowHerd.PlotSingleRandomStep();

            input('Finished question 2.3, press enter to continue');

            % 2.4 Create 10 cows
            % cowHerd = RobotCows(10);

            % 2.5 Many steps
            % numSteps = 100;
            % delay = 0.01;
            % cowHerd.TestPlotManyStep(numSteps, delay);

            % 2.6 Location of second cow
            % cowHerd.cowModel{2}.base

            input('Finished question 2, press enter to continue');
        end

%% Question 3: Combine UAV and cows
        function Question3()
            clf;
            hold on;

            % 3.1 Place two fences
            % PlaceObject('fenceFinal.ply',[ 5,0,0; -5,0,0 ]);

            % 3.2) Place another fence at [5,0,0] and rotate it by 90 degrees. Personalise your fencing
            % h = PlaceObject('fenceFinal.ply',[0,0,0]);
            % verts = [get(h,'Vertices'), ones(size(get(h,'Vertices'),1),1)] * trotz(pi/2);
            % verts(:,1) = verts(:,1) + 5;
            % set(h,'Vertices',verts(:,1:3))

            % 3.3 Create herd with more than 2 cows
            % cowHerd = RobotCows(3);

            % 3.4 Initial UAV pose
            % trplot(eye(4));

            % 3.5 Get transform between UAV and cows

            % 3.6 UAV flies through steps, use tranimate to simulate motion between steps (as in Question1)
            % move the cows randomly with
            % cowHerd.PlotSingleRandomStep();

            % 3.7) Fly the UAV path and compute transforms to all cows at each goal
            input('Finished questions 3.1-3.7, press enter to continue')
        end

%% Question 3.8: Create a cow herd with one cow and move your drone so that at each step 
        % the cow follows stays 5 meters above it but directly overhead
        function Question3point8()
            clf;
            % cowHerd = RobotCows(1);
            % Animate UAV to start above the cow, then follow as cow moves
        end

%% Question 4 Derive the DH parameters for the simple 3 link manipulator provided.
% Use these to generate a  model of the manipulator using the Robot Toolbox in MATLAB 
        function Question4()
            clf;
            clc;

            % 4.1) Work out the DH Parameters for the 3-link planar manipulator 
            %      (Hint: Use trial and error with 'a' and 'd' values)

            % 4.2) Create the robot using SerialLink and the 3 links
            %      L1 = Link('d', ..., 'a', ..., 'alpha', ..., 'qlim', [ -pi, pi ]);
            %      L2 = Link('d', ..., 'a', ..., 'alpha', ..., 'qlim', [ -pi, pi ]);
            %      L3 = Link('d', ..., 'a', ..., 'alpha', ..., 'qlim', [ -pi, pi ]);
            %      robot = SerialLink([L1 L2 L3], 'name', 'myRobot');
            %      q = zeros(1,n); % This creates a vector of n joint angles at 0.
            %      workspace = [-x +x –y +y –z +z];
            %      scale = 1;
            %      robot.plot(q,'workspace',workspace,'scale',scale); 

            % 4.3) Manually play around with the robot
            %      robot.teach();

            % 4.4) Get the current joint angles from the GUI position
            %      q = robot.getpos();

            % 4.5) Get the joint limits
            %      robot.qlim
        end
    end
end
