classdef Lab2Solution < handle
%#ok<*NASGU>
%#ok<*NOPRT>
%#ok<*TRYNC>

    properties (Constant)
        trSteps = {eye(4) ...
                    , transl([0,0,10]) ...
                    , transl([0,0,10]) * trotx(-30 * pi/180) ...
                    , transl([0,2,10]) * trotx(-30 * pi/180) ...
                    , transl([0,2,10]) ...
                    , transl([0,2,10]) * troty(30 * pi/180) ...
                    , transl([2,2,10]) * troty(30 * pi/180) ...
                    , transl([2,2,10]) ...
                    , transl([2,2,0]) };
    end

    methods 
		function self = Lab2Solution()
			clf
			clc
			input('Press enter to begin')
			self.Question1();
			self.Question2();
			self.Question3();
			self.Question3point8();
			self.Question4();
		end
	end

    methods(Static)
%% Question 1: Animate transform (Quad copter flying)
        function Question1()
            tic

			hold on;
            grid on
            axis equal
            view(3)
            axis([-1,4,-1,4,0,11]);

            trSteps = Lab2Solution.trSteps;

            for i = 2:length(trSteps)
				try delete(findobj(gca, 'Type', 'hgtransform')); end % Delete all transforms to delete tranimate's Transform 
				try delete(text_h); end % Delete the text_h 

				rpyValue = tr2rpy(trSteps{i});
				quaternionValue = UnitQuaternion(trSteps{i});
				message = sprintf(['rpy: ', num2str(rpyValue),'\n, quaternion: ', quaternionValue.char])  
								
				text_h = text(trSteps{i}(1,4),trSteps{i}(2,4),trSteps{i}(3,4), message,'FontSize', 10);
                tranimate(trSteps{i-1},trSteps{i},'fps',50);   
            end

			disp(['Q1 Tranimate took ', num2str(toc), 's'])
			input('Finished question 1, press enter to continue')
        end

%% Question 2: Plotting and moving the herd of RobotCows
        function Question2()
            clf;

            % 2.1 Create an instance of the cow herd with default parameters
            cowHerd = RobotCows();
            % 2.2 Check how many cow there are
            cowHerd.cowCount
            % 2.3 Plot on single iteration of the random step movement
            cowHerd.PlotSingleRandomStep();

            input('Finished question 2.3, press enter to continue')

            % 2.4 Clear then create another instance with 10 cows
            clf;
            try delete(cowHerd); end 
            cowHerd = RobotCows(10);
            % 2.5 Test many random steps
            numSteps = 100;
            delay = 0.01;
            cowHerd.TestPlotManyStep(numSteps,delay);
            % 2.6 Query the location of the 2nd cow 
            cowHerd.cowModel{2}.base

            input('Finished question 2, press enter to continue');
        end

%% Question 3: Combine question 1 with question 2
        function Question3()
            clf

            % 3.1 Place one fence (not keeping the handle)
            % PlaceObject('fenceFinal.ply',[ 5,0,0; -5,0,0 ]);
            hold on;

            % 3.2 Placing a fence and rotating it using the handle (you can
            % personalise this)
            % h = PlaceObject('fenceFinal.ply',[0,0,0]);
            % verts = [get(h,'Vertices'), ones(size(get(h,'Vertices'),1),1)] * trotz(pi/2);
            % verts(:,1) = verts(:,1) + 5;
            % set(h,'Vertices',verts(:,1:3))
			
			% 3.2 Personalised fence
            h_1 = PlaceObject('fenceFinal.ply',[5,0,0]);
            verts = [get(h_1,'Vertices'), ones(size(get(h_1,'Vertices'),1),1)] * trotz(pi/2);
            verts(:,1) = verts(:,1) * 20;
            set(h_1,'Vertices',verts(:,1:3))

            h_2 = PlaceObject('fenceFinal.ply',[-5,0,0]);
            verts = [get(h_2,'Vertices'), ones(size(get(h_2,'Vertices'),1),1)] * trotz(pi/2);
            verts(:,1) = verts(:,1) * 20;
            set(h_2,'Vertices',verts(:,1:3))

            h_3 = PlaceObject('fenceFinal.ply',[0,0,0]);
            verts = [get(h_3,'Vertices'), ones(size(get(h_3,'Vertices'),1),1)];
            verts(:,2) = verts(:,2) * 20;
            verts(:,1) = verts(:,1) + 5;
            set(h_3,'Vertices',verts(:,1:3))

            h_4 = PlaceObject('fenceFinal.ply',[0,0,0]);
            verts = [get(h_4,'Vertices'), ones(size(get(h_4,'Vertices'),1),1)];
            verts(:,2) = verts(:,2) * 20;
            verts(:,1) = verts(:,1) - 5;
            set(h_4,'Vertices',verts(:,1:3))

            % 3.3 Create a cow herd with more than 2 cows.
            cowHerd = RobotCows(3);

            % 3.4 Plot the transform of the UAV starting at the origin
            uavTR = eye(4);
            trplot(uavTR)

            % 3.5 Determine the transform between the UAV and each of the cows 
            for cowIndex = 1:cowHerd.cowCount
               disp(['At trajectoryStep ',num2str(1),' the UAV TR to cow ',num2str(cowIndex),' is ']);
               disp(num2str(inv(uavTR) * cowHerd.cowModel{cowIndex}.base.T)); %#ok<MINV>
            end  
            cowHerd.PlotSingleRandomStep();

			% 3.6-3.7 Fly through Question 1, at each time the UAV moves to
            % a goal, the cows move randomly once, then determine the transform 
            % between the UAV and all the cows 
            trSteps = Lab2Solution.trSteps;

            for i = 2:length(trSteps)
                tranimate(trSteps{i-1},trSteps{i},'fps',50); 
				uavTR = trSteps{i};
                cowHerd.PlotSingleRandomStep();
                for cowIndex = 1:cowHerd.cowCount
                   disp(['At trajectoryStep ',num2str(1),' the UAV TR to cow ',num2str(cowIndex),' is ']);
                   disp(num2str(inv(uavTR) * cowHerd.cowModel{cowIndex}.base.T)); %#ok<MINV>
                end                  
            end

            input('Finished questions 3.1-3.7, press enter to continue')
        end

%% Question3point8        
		function Question3point8()
            % 3.8 Create a cow herd with 1 cow and move your drone so that at each step the cow moves stay 5 meters above it but directly overhead
            clf;
            clc;
            cowHerd = RobotCows(1);
            
            tic

			% Animate copter to go over cow position
			uavTRStart = transl(0,0,5);
			uavTRGoal = uavTRStart * cowHerd.cowModel{1}.base.T;
			tranimate(uavTRStart,uavTRGoal,'fps',25)

            % Go through 10 steps (not specified but this is arbitary)
            for i = 1:10
                cowHerd.PlotSingleRandomStep();
                uavTRStart = uavTRGoal;
                uavTRGoal = cowHerd.cowModel{1}.base.T * transl(0,0,5);
                tranimate(uavTRStart,uavTRGoal,'fps',100);
            end

            disp(['Following the cow took ', num2str(toc), 's'])

            input('Finished question 3, press enter to continue')
        end

%% Question 4 Derive the DH parameters for the simple 3 link manipulator provided. 
% Use these to generate a  model of the manipulator using the Robot Toolbox in MATLAB 
        function Question4()
            clf;
            clc

            % 4.1 and 4.2: Define the DH Parameters to create the Kinematic 
			% model
            L1 = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi]) 
            L2 = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi]) 
            L3 = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi]) 

			% Generate the model
            robot = SerialLink([L1 L2 L3],'name','myRobot')          
            
            % Creates a vector of n joint angles at 0.
            q = zeros(1,robot.n); 

            % Set the size of the workspace when drawing the robot
            workspace = [-4 4 -4 4 -4 4];
            scale = 0.5;

            % Plot the robot
            robot.plot(q,'workspace',workspace,'scale',scale); 

            % 4.3 Manually play around with the robot
            robot.teach();

            % 4.4 Get the current joint angles based on the position in the model
            q = robot.getpos()  

            % 4.5 Get the joint limits
            robot.qlim 
        end
    end
end