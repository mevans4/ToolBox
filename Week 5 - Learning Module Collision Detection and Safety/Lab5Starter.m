classdef Lab5Starter < handle

%#ok<*NOPRT>

    methods
        function self = Lab5Starter()
			clf
            set(0,'DefaultFigureWindowStyle','docked')		
            self.Part1();
            self.Part2();
        end
    end

    methods (Static)
%% Part1
% Collision checking between a 1DOF robot and a sphere
        function Part1()
            clf

            % Changed sphere plot to allow for either point cloud or triangle mesh based on value of a boolean variable, 'makePointCloud'.
            makePointCloud = true;
			makeTriangleMesh = true;
            
            %% Create 1-link robot
            L1 = Link('d',0,'a',1,'alpha',0,'qlim',[-pi pi]);
            robot = SerialLink(L1,'name','myRobot');
            
            q = 0;                                                             
            scale = 0.5;
            workspace = [-0.5 1.5 -0.5 1.5 -1 1];                                      
            robot.plot(q,'workspace',workspace,'scale',scale);                 
            hold on;
            
            %% Create sphere
            sphereCenter = [1,1,0];
            radius = 0.5;
            [X,Y,Z] = sphere(20);
            X = X * radius + sphereCenter(1);
            Y = Y * radius + sphereCenter(2);
            Z = Z * radius + sphereCenter(3);
            
            %% Plot it
            if makePointCloud
                % Plot point cloud
                points = [X(:),Y(:),Z(:)];
                spherePc_h = plot3(points(:,1),points(:,2),points(:,3),'r.');                
            end
			if makeTriangleMesh
                % Triangle mesh plot
                tri = delaunay(X,Y,Z);
                sphereTri_h = trimesh(tri,X,Y,Z);
            end
                        
            drawnow();
            view(3)
            axis equal
            
            %% Move Robot
            for q = 0:pi/180:pi/2
                robot.animate(q);
                drawnow();
                pause(0.1);

                %% Change code to choose the behaviour 
                % (1) Do this to move through obstacles with a message
                Lab5Starter.CheckCollision(robot,sphereCenter,radius);
                % OR (2) stop the movement when an obstacle is detected
                % if Lab5Starter.CheckCollision(robot,sphereCenter,radius) == 1
                %     disp('UNSAFE: Robot stopped')
                %     break
                % end
            end
        end

%% Part2
% As well as the way shown in the previous part, there is also
% another function in the toolbox called LinePlaneIntersection.     
        function Part2()
            clf
            % A plane can be defined with the following point and normal vector
            planeNormal = [-1,0,0];
            planePoint = [1.5,0,0];
            
            % Then if we have a line (perhaps a robot's link) represented by two points:            
            lineStartPoint = [-0.5,0,0];
            lineEndPoint = [3.5,0,0];
            
            % Then we can use the function to calculate the point of
            % intersection between the line (line) and plane (obstacle) 
            [intersectionPoints,check] = LinePlaneIntersection(planeNormal,planePoint,lineStartPoint,lineEndPoint);
            
            % The returned values and their means are as follows:
            % (1) intersectionPoints, which shows the xyz point where the line
            intersectionPoints
            
            % (2) check intersects the plane check, which is defined as follows:
            check 
            % Check == 0 if there is no intersection
            % Check == 1 if there is a line plane intersection between the two points
            % Check == 2 if the segment lies in the plane (always intersecting)
            % Check == 3 if there is intersection point which lies outside line segment
            
            % We can visualise this as follows by first creating and
            % plotting a plane, which conforms to the previously defined planePoint and planeNormal                
            [Y,Z] = meshgrid(-2:0.1:2,-2:0.1:2);
            X = repmat(1.5,size(Y,1),size(Y,2));
            surf(X,Y,Z);
            
            % Then plot the start and end point in green and red, respectively.            
            hold on;
            plot3(lineStartPoint(1),lineStartPoint(2),lineStartPoint(3) ,'g*');
            plot3(lineEndPoint(1),lineEndPoint(2),lineEndPoint(3) ,'r*');
            plot3([lineStartPoint(1),lineEndPoint(1)],[lineStartPoint(2),lineEndPoint(2)],[lineStartPoint(3),lineEndPoint(3)] ,'k');
            plot3(intersectionPoints(1),intersectionPoints(2),intersectionPoints(3) ,'k*','MarkerSize',20);

            axis equal
        end

%% CheckCollision
% Checks for collisions with a sphere and can be modified to return an
% isCollision result
        function CheckCollision(robot, sphereCenter, radius)
        % function isCollision = CheckCollision(robot, sphereCenter, radius)

            tr = robot.fkine(robot.getpos).T;
            endEffectorToCenterDist = sqrt(sum((sphereCenter-tr(1:3,4)').^2));
            if endEffectorToCenterDist <= radius
                disp('Oh no a collision!');
        %         isCollision = 1;
            else
                disp(['SAFE: End effector to sphere centre distance (', num2str(endEffectorToCenterDist), 'm) is more than the sphere radius, ' num2str(radius), 'm']);
        %         isCollision = 0;
            end
        
        end
    end
end

