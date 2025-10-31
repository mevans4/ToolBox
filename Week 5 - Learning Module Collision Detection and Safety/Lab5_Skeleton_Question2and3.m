classdef Lab4Skeleton < handle
    methods
        function self = Lab4Skeleton()
            close all
            set(0,'DefaultFigureWindowStyle','docked')
            clc

            % You can run these individually when ready:
            % self.Question2();
            % self.Question3();
        end
    end

    methods (Static)
        function Question2()
            %% 2) Simple collision checking for 3-link planar robot
            
            %% 2.1) Create a 3 link planar robot with all 3 links having a = 1m, leave the base at eye(4).
            % L1 = Link('d',___,'a',___,'alpha',___,'qlim',[___ ___]);
            % L2 = Link('d',___,'a',___,'alpha',___,'qlim',[___ ___]);
            % L3 = Link('d',___,'a',___,'alpha',___,'qlim',[___ ___]);
            % robot = SerialLink([___ ___ ___],'name','___');
            % q = zeros(1,3);
            % scale = 0.5;
            % workspace = [-2 2 -2 2 -0.05 2];
            % robot.plot(q,'workspace',workspace,'scale',scale);

            %% 2.2) Put a cube with sides 1.5m in the environment that is centered at [2,0,-0.5]. 
            %% You may like to use the "RectangularPrism" function that is specially prepared for this exercise.
            % centerpnt = [___, ___, ___];
            % side = ___;
            plotOptions.plotFaces = true;
            [vertex,faces,faceNormals] = RectangularPrism(centerpnt-side/2, centerpnt+side/2,plotOptions);
            axis equal
            camlight

            %% 2.3) Use teach and note when the links of the robot can collide with 4 of the planes:
            %% Plane 1: point [1.25,0,-0.5] normal [-1,0,0]
            %% Plane 2: point [2,0.75,-0.5] normal [0,1,0]
            %% Plane 3: point [2,-0.75,-0.5] normal [0,-1,0]
            %% Plane 4: point [2.75,0,-0.5] normal [1,0,0]
            % robot.teach;

            %% 2.4) Using your understanding of forward kinematics write a function that you can pass in 
            %% vector of joint angles, q, to represent a joint state of the arm, and it will return a 4x4x4 matrix, TR which contains
            %% TR(:,:,1) = arm.base
            %% TR(:,:,2) = Transform at end of link 1
            %% TR(:,:,3) = Transform at end of link 2
            %% TR(:,:,4) = arm.fkine(q)
             
            % tr = zeros(4,4,robot.n+1);	% Preallocate a 3D matrix to store the 4x4 transforms
            % tr(:,:,1) = robot.base;		% Set first matrix to be the base transform
            % L = robot.links;			% Obtain the robot links information (e.g. DH parameters)
            %% HINT: Loop through all joints 'robot.n', each iteration define the next joint pose using the current joint pose through DH parameters
            %% Remember: joint_i+1 = joint_i * z_rotation(q + offset) * z_translation(0,0,d) * x_translation(a,0,0) * x_rotation(alpha)
            %% The rotation and translation about Z have their parameters filled in, you need to find the function name.
            % for i = 1 : ___
            %     tr(:,:,i+1) = tr(:,:,___) * ___(q(i)+L(i).offset) * ___(0,0,L(i).d) * ___ * ___;
            % end

            %% 2.5) Use the LinePlaneIntersection function to check if any of the links (i.e. the link n) intersects with any of the 4 planes of 
            %% the cube when q = [0,0,0]. 
            % Note how the link n is a line from position TR(1:3,4,n-1) to TR(1:3,4,n)

            %% 2.6) Use q1 = [-pi/4,0,0], q2 = [pi/4,0,0], jtraj(q1,q2,steps) to get a trajectory from q1 to q2 
            %% and pick a value for steps such that the size of each step is less than 1 degree. 
            %% Hint: look at the step size in degrees using diff(rad2deg(jtraj(q1,q2,steps)))
            q1 = [-pi/4,0,0];
            q2 = [pi/4,0,0];
            steps = 2;
            while ~isempty(find(1 < abs(diff(rad2deg(jtraj(q1,q2,steps)))),1))
                steps = steps + 1;
            end
            qMatrix = jtraj(q1,q2,steps);

            %% 2.7) Check each of the joint states in the trajectory to work out which ones are in collision. 
            %% Return a logical vector of size steps which contains 0 = no collision (safe) and 1 = yes collision (Unsafe). 
            %% You may like to use this structure.
            result = true(steps,1);
            for i = 1: steps
                result(i) = CollisionCheck(robot,q1,q2);
            end
        end

        function Question3()
            %% 3) Basic collision avoidance for 3-link planar robot
            %% Determine a path from pose q1 = [-pi/4,0,0] degrees to q2 = [pi/4,0,0] that doesn't collide with the cube from previous question. 
            %% Use the following 3 methods:

            %% 3.1) Method 1: Manually determine intermediate joint states that are not in collision with the cube using teach. 
            %% Then make a path that goes between way points
            %% E.g. qWaypoints = [q1; q2; q3; ...];

            % 3.2) Method 2: Manually determine Cartesian points (i.e. [x,y,z] points) that the end effector could follow 
            % such that the end effector does not go inside the cube
            %% E.g. q3 = robot.ikcon(transl(x,y,z),q2);
            %% qWaypoints = [qWaypoints; q3];

            %% 3.3, 3.4, 3.5) Method 3: Now, iteratively, randomly and automatically pick a pose within the joint angle bounds
            % q = (2 * rand(1,3) - 1) * pi
           
            %% Then interpolate between current pose and this new pose. If all the results are equal to 0 then the path is collision-free:
            % all(~results) == true

            %% At each step try and connect from the current joint state to the final goal state. Keep upon concatenating the joint trajectory until you can reach the goal
        end
    end
end
