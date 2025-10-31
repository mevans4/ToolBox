classdef Lab3Solution < handle
%#ok<*NOPRT>
%#ok<*TRYNC>
%#ok<*AGROW>

    methods
        function self = Lab3Solution()
         	close all
            set(0,'DefaultFigureWindowStyle','docked')
            clc
            self.Question1(0);
            self.Question1(1);
            self.Question1(2);
            self.Question1(3);
            self.Question1(4);

            self.Question2();
            self.Question3();
        end
    end

    methods (Static)
		%% Question 1: Derive the DH parameters for each of the manipulators provided. Use these to generate a model of the manipulator using the Robot Toolbox in MATLAB. 
		% modelIndex the type of robot to plot
		% 0 = Week 2 - 3-Link Planar Robot
		% 1 = 3-Link 3D Robot
		% 2 = AANBOT UR10 arm
		% 3 = SPIR Igus arm
		% 4 = Sawyer Robot (7DOF)

        function Question1(modelIndex)
            clf
			if nargin < 1
				modelIndex = 1;
				display(['No model passed so assuming model ',num2str(modelIndex)]);
			end

			% 1.2) Use the DH parameters to generate the robot model with the Robotics Toolbox. Note: Robots 1 and 2 have zero values for their 'offset' parameters.
            switch modelIndex
                case 0   % Week 2 - 3-Link Planar Robot
                    link(1) = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi]);
                    link(2) = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi]);
                    link(3) = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi]);
                    % Generate the robotModel
                    robotModel = SerialLink(link,'name','3-Link Planar Robot')

                case 1 % 3-Link 3D Robot
                    link(1) = Link('d',1,'a',0,'alpha',pi/2,'qlim',[-pi/2 pi/2]);
                    link(2) = Link('d',0,'a',1,'alpha',0,'qlim',[-pi/2 pi/2]);
                    link(3) = Link('d',0,'a',1,'alpha',-pi/2,'qlim',[-pi/2 pi/2]);
                    robotModel = SerialLink(link,'name','3-Link 3D Robot')

                case 2 % AANBOT UR10 arm
    	            link(1) = Link('d',0.1273,'a',0,'alpha',pi/2,'offset',0);
                    link(2) = Link('d',0,'a',-0.612,'alpha',0,'offset',0);
                    link(3) = Link('d',0,'a',-0.5723,'alpha',0,'offset',0);
                    link(4) = Link('d',0.163941,'a',0,'alpha',pi/2,'offset',0);
                    link(5) = Link('d',0.1157,'a',0,'alpha',-pi/2,'offset',0);
                    link(6) = Link('d',0.0922,'a',0,'alpha',0,'offset',0);
                    robotModel = SerialLink(link,'name','AANBOT UR10 arm')

                case 3 % SPIR Igus arm
    	            link(1) = Link('d',0.09625,'a',0,'alpha',pi/2,'offset',0,'qlim',[deg2rad(-90),deg2rad(90)]);
                    link(2) = Link('d',0,'a',0.27813,'alpha',0,'offset',1.2981,'qlim',[deg2rad(-74.3575),deg2rad(105.6425)]);
                    link(3) = Link('d',0,'a',0,'alpha',-pi/2,'offset',-2.8689,'qlim',[deg2rad(-90),deg2rad(90)]);
                    link(4) = Link('d',0.23601,'a',0,'alpha',pi/2,'offset',0,'qlim',[deg2rad(-135),deg2rad(135)]);
                    link(5) = Link('d',0,'a',0,'alpha',-pi/2,'offset',0,'qlim',[deg2rad(-90),deg2rad(90)]);
                    link(6) = Link('d',0.13435,'a',0,'alpha',0,'offset',0,'qlim',[deg2rad(-135),deg2rad(135)]);
                    robotModel = SerialLink(link,'name','SPIR Igus arm')

                case 4 % Sawyer
                    r = Sawyer;
                    % Just for this question we take a copy of the robot
                    % model out from the class. 
                    % This is bad MATLAB programming practice.
                    % So PLEASE DON'T do this in future!
                    robotModel = r.model
            end

			% Set the size of the workspace when drawing the robotModel
			roughMinMax = sum(abs(robotModel.d) + abs(robotModel.a));
			workspace = [-roughMinMax roughMinMax -roughMinMax roughMinMax -0.01 roughMinMax];
            scale = 0.5;

            % Create a vector of initial joint angles
            q = zeros(1,robotModel.n);
            % Plot the robotModel
            robotModel.plot(q,'workspace',workspace,'scale',scale);

            % 1.3) Use teach to change the q variable (i.e. the values for each joint), and check that the model matches the images provided. 
            robotModel.teach(q);
            input('Use teach to move the robot into a new position and then press enter to continue');

            % 1.4) Get the current joint angles in radians from the current plot of the model.
            q = robotModel.getpos();

			% 1.5) Calculate the transformation matrix of the end effector at a particular joint angle, q, using:
            T = robotModel.fkine(q);
            
            % 1.6) Reverse this and use the end effector transformation, T, and find the joint angles, q.
            if robotModel.n == 6
                q = robotModel.ikine(T); % N.B. DOES NOT WORK FOR 3DOF MANIPULATORS
            end
            
            % 1.7) Get the Jacobian matrix in the base frame, which maps joint velocities to end-effector velocities.
            J = robotModel.jacob0(q);
            
            % 1.8) Try and invert the Jacobian, both with and without the above command, J(1:3,1:3), which limits the Jacobian to the first 3 joint velocities and translational velocities for the end effector.
            % Try to invert the full Jacobian - what happens?
            try 
                inv(J) 
            catch ME_1
                disp(ME_1)
            end

            % Select the first 3 rows and colums to show how the first 3
            % joints affect the end effector position
            try
                J = J(1:3,1:3); % For the 3-Link robots, we only need the first 3 rows. You should try it both with and without for the 6DOF robots.
                inv(J) 
                % 1.10) You can visualise how fast the end-effector can move in Cartesian space with the following command:
                robotModel.vellipse(q);
            catch ME_1
                disp(ME_1)
            end 
            
            % % 1.9) The Jacobian can't be inverted at certain joint configurations (potentially like the one below). Check to see if there are other configurations where this happens. 
            % q = zeros(1,robotModel.n)
            % J = robotModel.jacob0(q)
            % inv(J)
                                  
            % 1.11) Show what the velocity ellipse looks like when the Jacobian “J” can’t be inverted?
        end

		%% Question 2
        function Question2()
			profile clear;
			profile on;

            % 2.1 Determine the D&H parameters based upon the link
            % measurements on the PDF
            % & 2.2 Determine and include the joint limits in your model
            link(1) = Link('alpha',-pi/2,'a',0.180, 'd',0.475, 'offset',0, 'qlim',[deg2rad(-170), deg2rad(170)]);
            link(2) = Link('alpha',0,'a',0.385, 'd',0, 'offset',-pi/2, 'qlim',[deg2rad(-90), deg2rad(135)]);
            link(3) = Link('alpha',pi/2,'a',-0.100, 'd',0, 'offset',pi/2, 'qlim',[deg2rad(-80), deg2rad(165)]);
            link(4) = Link('alpha',-pi/2,'a',0, 'd',0.329+0.116, 'offset',0, 'qlim',[deg2rad(-185), deg2rad(185)]);
            link(5) = Link('alpha',pi/2,'a',0, 'd',0, 'offset',0, 'qlim',[deg2rad(-120), deg2rad(120)]);
            link(6) = Link('alpha',0,'a',0, 'd',0.09, 'offset',0, 'qlim',[deg2rad(-360), deg2rad(360)]);

            densoRobot = SerialLink(link,'name','Denso VM6083G');
            densoRobot.plotopt = {'nojoints', 'noname', 'noshadow', 'nowrist'};

            % Plotting robot at zero position
            densoRobot.plot(zeros(1,6));
            input('Press enter to continue');

            % Hold on so point cloud is visible around robot.
            hold on;

            % 2.3 Sample the joint angles within the joint limits at 30
            % degree increments between each of the joint limits
            % & 2.4 Use fkine to determine the point in space for each of
            % these poses, so that you end up with a big list of points
            stepRads = deg2rad(30);
            qlim = densoRobot.qlim;

            % Preallocate size and don't worry iterating through joint 6
            pointCloudeSize = prod(floor((qlim(1:5,2)-qlim(1:5,1))/stepRads + 1));
            pointCloud = zeros(pointCloudeSize,3);
            counter = 1;

			% If using fkine and passing the whole trajectory
			qAll = zeros(pointCloudeSize,6);

			% Precalculate the DH transforms for an RRRRRR robot for speed
			baseTr = densoRobot.base.T;
			for i = 1:densoRobot.n
				% From the Canvas learning module on DH parameters
				T_zd = [1,0,0,0;0,1,0,0;0,0,1,densoRobot.links(i).d;0,0,0,1];
				T_xa = [1,0,0,densoRobot.links(i).a;0,1,0,0;0,0,1,0;0,0,0,1];
				cosAlpha = cos(densoRobot.links(i).alpha); 
				sinAlpha = sin(densoRobot.links(i).alpha); 
				T_Rx = [1,0,0,0;0,cosAlpha,-sinAlpha,0;0,sinAlpha,cosAlpha,0;0,0,0,1];
				transl_d_x_transl_a_x_trotx_alpha{i} = T_zd * T_xa * T_Rx; 
				thetaOffset(i) = densoRobot.links(i).offset;
			end
			densoRobotTool = densoRobot.tool.T;

            %% Go through all the poses
            tic

            for q1 = qlim(1,1):stepRads:qlim(1,2)
                for q2 = qlim(2,1):stepRads:qlim(2,2)
                    for q3 = qlim(3,1):stepRads:qlim(3,2)
                        for q4 = qlim(4,1):stepRads:qlim(4,2)
                            for q5 = qlim(5,1):stepRads:qlim(5,2)
                            
                                % Don't need to worry about joint 6, just
                                % assume it is 0
                                q6 = 0;
                                % for q6 = qlim(6,1):stepRads:qlim(6,2)
								q = [q1,q2,q3,q4,q5,q6];

								% Method (1v1): Original fkine from the
								% toolbox (1x = baseline speed)
								% Approx. 100s for ~100k loops with
                                % V10 TB
								trFKineMethod1 = densoRobot.fkine(q).T;

								% Method (2v2): UTS modified version
								% adapted from V9 fkine for V10
								% compatibility (~10x faster)
								trFKineMethod2 = densoRobot.fkineUTS(q);

								% Method (3): Manually calculate fkine
								% without toolbox (~200x faster). Warning
								% implemenation makes assumptions that may
								% cause compatability issues with other
								% robots! 
								trFKineMethod3 = baseTr;
								for i = 1:densoRobot.n
								% Don't forget about adding the offset to q
								thetaPlusOffset = q(i) + thetaOffset(i);
								T_Rz = [cos(thetaPlusOffset), -sin(thetaPlusOffset),0,0; ....
								sin(thetaPlusOffset),  cos(thetaPlusOffset),0,0;...
								0,0,1,0;0,0,0,1];
								trFKineMethod3 = trFKineMethod3 * T_Rz * transl_d_x_transl_a_x_trotx_alpha{i};
								end
								trFKineMethod3 = trFKineMethod3 * densoRobotTool;

								% Check similarity of results from the
                                % methods
								if ~isempty(find(0.001 < trFKineMethod1 - trFKineMethod2,1))... 
								|| ~isempty(find(0.001 < trFKineMethod2 - trFKineMethod3,1))
									warning('Results from the methods are not identical')
									trFKineMethod1
									trFKineMethod2
									trFKineMethod3
								end

								% Use the results from a method
								tr = trFKineMethod3;

								pointCloud(counter,:) = tr(1:3,4)';
								qAll(counter,:) = q;
								counter = counter + 1; 
								if mod(counter/pointCloudeSize * 100,1) == 0
									disp(['After ',num2str(toc),' seconds, completed ',num2str(counter/pointCloudeSize * 100),'% of poses']);
								end
            %                     end
                            end
                        end
                    end
                end
            end
			toc

			% Method (1v2): Original fkine from the toolbox UTS but done as
			% one trajectory (faster)
			tic
			trFKineMethod1v2 = densoRobot.fkine(qAll);
			trFKineMethod1v2_T = trFKineMethod1v2.T;
			pointCloudMethod1v2 = squeeze(trFKineMethod1v2_T(1:3,4,:))';
			disp(['Method 1v2 ',num2str(toc)])            

			% Method (2v2): UTS modified version adapted from V9 fkine for
			% V10 compatibility, then done as one trajectory (faster)
			tic
			trFKineMethod2v2 = densoRobot.fkineUTS(qAll);
			pointCloudMethod2v2 = squeeze(trFKineMethod2v2(1:3,4,:))';
			disp(['Method 2v2 ',num2str(toc)])

			% 2.5 Create a 3D model showing where the end effector can be
			% over all these samples.  
			plot3(pointCloud(:,1),pointCloud(:,2),pointCloud(:,3),'r')

            profile off;
			profile viewer;
        end

		%% Grit blasting with a Denso VM-6083D-W
        function Question3()
            clf
            % 3.1 Load the DensoVM6083 from the toolbox
            densoRobot = DensoVM6083;

            % 3.2 Move to the following joint state, then get the start of
            % the blast using fkine (to get end effector transform)
            q = [0,pi/2,0,0,0,0];
            densoRobot.model.animate(q);            

            blastStartTr = densoRobot.model.fkine(q).T;
            blastStartPoint = blastStartTr(1:3,4)';

            % 3.3 Get the end of the stream with TR * transl (blast stream
            % length (i.e. 1m along z)
            blastEndTr = densoRobot.model.fkine(q).T * transl(0,0,1);
            blastEndPoint = blastEndTr(1:3,4)';

            % 3.4 Use "hold on" then add a red line that is projected out
            % of the end effector (i.e. a mock grit-blasting stream).
            hold on;
            blastPlot_h = plot3([blastStartPoint(1),blastEndPoint(1)],[blastStartPoint(2),blastEndPoint(2)],[blastStartPoint(3),blastEndPoint(3)],'r');
            axis equal;

			% 3.5 Create a surface plane that goes through [1.5,0,0] with a
            % normal [-1,0,0]
			planeXntersect = 1.5;
			planeBounds = [planeXntersect-eps,planeXntersect+eps,-2,2,-2,2]; 
			[Y,Z] = meshgrid(planeBounds(3):0.1:planeBounds(4),planeBounds(5):0.1:planeBounds(6));
            X = repmat(planeXntersect,size(Y,1),size(Y,2));
            wall_h = surf(X,Y,Z);

            % 3.6 Determine if and where the blast stream intersects with
            % the surface plane
            planePoint = [1.5,0,0];
            planeNormal = [-1,0,0];

            [intersectionPoints,check] = LinePlaneIntersection(planeNormal,planePoint,blastStartPoint,blastEndPoint);
            if check == 1
                intersectionPointPlot_h = plot3(intersectionPoints(:,1),intersectionPoints(:,2),intersectionPoints(:,3),'g*');
            end

			pause

            % 3.7 Move the robot around some random joint states, keeping
            % joints 1,2,3 = [0,pi/2,0] so the robot  faces the wall.
            jointMidRadians = sum(densoRobot.model.qlim,2)'/2;
            for i = 1:10
                % Pick a random joint configuration with some joints set
                % and other close to 0s and move arm there
                goalQ = [0,pi/2,0,jointMidRadians(4:6) + 0.5 * (rand(1,3)-0.5) .* (densoRobot.model.qlim(4:6,2)' - densoRobot.model.qlim(4:6,1)')];

                % Get a trajectory
                jointTrajectory = jtraj(densoRobot.model.getpos(),goalQ,20);
                for trajStep = 1:size(jointTrajectory,1)
                    q = jointTrajectory(trajStep,:);
                    densoRobot.model.animate(q);
                    
					blastStartTr = densoRobot.model.fkine(q).T;
					blastStartPoint = blastStartTr(1:3,4)';
					           
					blastEndTr = densoRobot.model.fkine(q).T * transl(0,0,1);
					blastEndPoint = blastEndTr(1:3,4)';

					[intersectionPoints(end+1,:),check] = LinePlaneIntersection(planeNormal,planePoint,blastStartPoint,blastEndPoint);

					if check == 1 ...
					&& all(planeBounds([1,3,5]) < intersectionPoints(end,:)) ... 
					&& all(intersectionPoints(end,:) < planeBounds([2,4,6]))
						try delete(intersectionPointPlot_h);end 
						intersectionPointPlot_h = plot3(intersectionPoints(:,1),intersectionPoints(:,2),intersectionPoints(:,3),'g*');
						blastEndPoint = intersectionPoints(end,:);
					end

					try delete(blastPlot_h); end
					blastPlot_h = plot3([blastStartPoint(1),blastEndPoint(1)] ...
									   ,[blastStartPoint(2),blastEndPoint(2)] ...
									   ,[blastStartPoint(3),blastEndPoint(3)],'r');

					drawnow();
                    pause(0.2);
                end
            end
		end
    end
end

