%% Aubo i5 Robot
% https://www.aubo-cobot.com/public/i5product3?CPID=i5

classdef AuboI5 < RobotBaseClass
    %% Robot Class Properties
    % Constant Properties
    properties (Access = public, Constant)
        initialJointAngles = deg2rad([0 135 -105 150 -90 0]);   % Default starting pose for Aubo i5
        movementSteps = 100;                                    % Number of steps allocated for movement trajectories
        movementTime = 10;                                      % Time for movements undergone by the Aubo i5
        epsilon = 0.01;                                         % Maximum measure of manipulability to then require Damped Least Squares
        movementWeight = diag([1 1 1 0.5 0.5 0.5]);             % Weighting matrix for movement velocity vector
        maxLambda = 5E-2;                                       % Value used for Damped Least Squares
        delta = 2*pi/1000;                                      % Small angle change for trajectory
    end

    % Non-constant Properties
    properties (Access = public)
        currentJointAngles;                                     % Current joint angles of the Aubo i5
        tool = cell(1,2);                                       % Variable to store the tool (2F-85 Gripper) that is used by the Aubo i5
        plyFileNameStem = 'AuboI5';                             % Name stem used to find associated ply files
        ellipsis;                                               % Stores the elipsoid robot object to check for collisions
        ellipsoids = zeros(1,7);                                % Structures that hold collision ellipsoid data
        linkCentres = zeros(7,3);                               % Structure of link centres to use for ellipsoid updating
 % Structure of link elliposid radii
        centreOffset =  [0 0 -0.25;
                        -0.3 0 -0.15;
                         -0.3 0 -0.05;
                               0 0.1 0;
                               0 -0.1 0;
                               0 0 0];
    end

    %% ...structors
    methods
        %% Constructor for Aubo i5 Robot
        function self = AuboI5(baseTr,L)
            % Setting the default base transform if not set within
            % constructor inputs
            if nargin < 2
                % Creating log file if not supplied (indicates it hasn't
                % been created yet)
                L = log4matlab('logFile.log');
                L.SetCommandWindowLevel(L.DEBUG);

                if nargin < 1
                    % Logging that the default base transform has been used
                    L.mlog = {L.DEBUG,'AuboI5','Base transform not set. Default base transform used'};
                    baseTr = eye(4); % Setting base transform as default
                end
            end

            self.CreateModel();                                                         % Creating the Aubo i5 D&H parameter model
            self.model.base = self.model.base.T * baseTr;                               % Orientating the Aubo i5 within the workspace
            self.ellipsis.base = self.ellipsis.base.T * baseTr;
            self.homeQ = self.initialJointAngles;                                       % Setting initial pose of Aubo i5
            self.PlotAndColourRobot();                                                  % Plotting the Aubo i5 and associated ply models
            L.mlog = {L.DEBUG,'AuboI5','Aubo i5 object created within the workspace'};  % Logging the creation of the Aubo i5

            % Creating 2F-85 gripper and attaching it to the Aubo i5 end-effector
            self.UpdateToolTr; % Updating the end-effector transform property
        end

        %% D&H Parameter Serial Link Creation
        function CreateModel(self)
            % D&H parameters for the Aubo i5 model
            % DH = [THETA D A ALPHA SIGMA OFFSET]
            % https://www.aubo-cobot.com/public/i5product3?CPID=i5
            link(1) = Link([0    0.1215   0        pi/2   0   0]);
            link(2) = Link([0    0        0.4080   0      0   0]);
            link(3) = Link([0    0        0.3760   0      0   0]);
            link(4) = Link([0   -0.1215   0        pi/2   0   0]);
            link(5) = Link([0    0.1025   0        pi/2   0   0]);
            link(6) = Link([0    0.0940   0        0      0   0]);

            % Qlims for each joint
            % https://www.aubo-cobot.com/public/i5product3?CPID=i5
            link(1).qlim = [-90   90] * pi/180;
            link(2).qlim = [5     175] * pi/180;
            link(3).qlim = [-175  175] * pi/180;
            link(4).qlim = [-360  360] * pi/180;
            link(5).qlim = [-360  360] * pi/180;
            link(6).qlim = [-360  360] * pi/180;

            % Creating the serial link object
            self.model = SerialLink(link,'name',self.name);
            self.ellipsis = SerialLink(link,'name',[self.name,'_ellipsis']);
        end

        %% Updater for End Effector Transform (Tool Transform)
        function UpdateToolTr(self)
            % Updating the toolTr property of the robot
            % Used to update the pose of the gripper to the end-effector
            self.currentJointAngles = self.model.getpos();              % Getting the current joint angles of Aubo i5
            self.toolTr = self.model.fkine(self.currentJointAngles).T;  % Updating toolTr property
        end

        %% Moving the Aubo i5 Joint to Specified Angles
        function MoveJoint(self, jointIndex, JointValue)
            % Getting the current joint angles of the Aubo i5 and updating
            % the joint value of the specified index
            self.currentJointAngles = self.model.getpos();
            self.currentJointAngles(str2double(jointIndex)) = deg2rad(JointValue);

            % Animating the robot and updating its toolTr to move the grippers
            self.model.animate(self.currentJointAngles);
            self.UpdateToolTr();
            
            % Updating the position of the grippers
            for gripperNum = 1:2
                self.tool{gripperNum}.UpdateGripperPosition(self.toolTr,gripperNum);
            end
            drawnow; % Updating the plot
        end

        %% Moving the Aubo i5 End-Effector to Specified Cartesian 
        function MoveToCartesian(self, coordinate, orientation)
            % Creating the transform for the dobot magician to move to
            self.UpdateToolTr();        % Getting the end-effector transform
            rotm = rpy2r(orientation);  % Getting the rotation matrix of the end-effector
            rotm = rotm(1:3,1:3);       % Getting only the rotation component of the transform
            transform = [rotm coordinate'; zeros(1,3) 1];
            
            % Getting the qMatrix to move the dobot magician to the cartesian coordiante
            qMatrix = self.GetCartesianMovement(transform);

            % Looping through the qMatrix to move the dobot magician
            for i = 1:size(qMatrix, 1)
                self.model.animate(qMatrix(i,:));   % Animating the dobot magician's movement and updating the gripper position
                self.UpdateToolTr();                % Updating the end-effector transform of the 

                % Updating the position of the grippers
                for gripperNum = 1:2
                    self.tool{gripperNum}.UpdateGripperPosition(self.toolTr,gripperNum);
                end
                drawnow; % Updating the plot
            end
        end

        %% Getting the qMatrix to Return Aubo i5 to Original Joint States
        function qMatrix = ReturnAuboToInitialPose(self)
            currentJointStates = self.model.getpos();                                           % Getting the current joint states of the robot
            qMatrix = jtraj(currentJointStates, self.initialJointAngles, self.movementSteps);   % Creating qMatrix using jtraj
        end

        %% Moving the Aubo i5 to a Desired Transform
        function qMatrix = GetCartesianMovement(self, coordinateTransform)
            deltaT = self.movementTime/self.movementSteps;      % Calculating discrete time step

            % Allocating memory to data arrays
            manipulability = zeros(self.movementSteps, 1);      % Array of measure of manipulability
            qMatrix = zeros(self.movementSteps, self.model.n);  % Array of joint angle states
            qdot = zeros(self.movementSteps, self.model.n);     % Array of joint velocities
            theta = zeros(3, self.movementSteps);               % Array of end-effector angles
            trajectory = zeros(3, self.movementSteps);          % Array of x-y-z trajectory

            % Getting the initial and final x-y-z coordinates
            initialTr = self.model.fkine(self.model.getpos()).T;    % Getting the transform for the robot's current pose
            x1 = initialTr(1:3,4);                                  % Extracting the x-y-z coordinates from the current pose transform
            x2 = coordinateTransform(1:3,4);                        % Extracting  the x-y-z coordiantes from the final pose transform

            % Getting the initial and final roll-pitch-yaw angles
            rpy1 = tr2rpy(initialTr(1:3,1:3));                      % Getting the inial roll-pitch-yaw angles
            rpy2 = tr2rpy(coordinateTransform(1:3,1:3));            % Getting the final roll-pitch-yaw angles

            % Creating the movement trajectory
            s = lspb(0,1,self.movementSteps);               % Create interpolation scalar
            for i = 1:self.movementSteps
                trajectory(:,i) = x1*(1-s(i)) + s(i)*x2;    % Creating the translation trajectory
                theta(:,i) = rpy1*(1-s(i)) + s(i)*rpy2;     % Creating the rotation trajectory
            end

            % Creating the transform for the first instance of the trajectory
            firstTr = [rpy2r(theta(1,1), theta(2,1), theta(3,1)) trajectory(:,1); zeros(1,3) 1];
            q0 = self.model.getpos();                       % Getting the initial guess for the joint angles
            qMatrix(1,:) = self.model.ikcon(firstTr, q0);   % Solving the qMatrix for the first waypoint

            % Tracking the movement trajectory with RMRC
            for i = 1:self.movementSteps-1
                currentTr = self.model.fkine(qMatrix(i,:)).T;           % Getting the forward transform at current joint states
                deltaX = trajectory(:,i+1) - currentTr(1:3,4);          % Getting the position error from the next waypoint
                Rd = rpy2r(theta(1,i+1), theta(2,i+1), theta(3,i+1));   % Getting the next RPY angles (converted to rotation matrix)
                Ra = currentTr(1:3,1:3);                                % Getting the current end-effector rotation matrix
                
                Rdot = (1/deltaT) * (Rd-Ra);                            % Calcualting the roll-pitch-yaw angular velocity rotation matrix
                S = Rdot * Ra';
                linearVelocity = (1/deltaT) * deltaX;                   % Calculating the linear velocities in x-y-z
                angularVelocity = [S(3,2);S(1,3);S(2,1)];               % Calcualting roll-pitch-yaw angular velocity
                xdot = self.movementWeight*[linearVelocity; angularVelocity]; % Calculate end-effector matrix to reach next waypoint

                J = self.model.jacob0(qMatrix(i,:)); % Calculating the jacobian of the current joint state

                % Implementing Damped Least Squares
                manipulability(i,1) = sqrt(det(J*J'));                  % Calcualting the manipulabilty of the aubo i5
                if manipulability(i,1) < self.epsilon                   % Checking if manipulability is within threshold
                    lambda = (1 - (manipulability(i,1)/self.epsilon)^2) * self.maxLambda; % Damping Coefficient
                    
                else % If DLS isn't required
                    lambda = 0; % Damping Coefficient
                end

                invJ = inv(J'*J + lambda * eye(self.model.n))*J';       %#ok<MINV> % DLS inverse
                qdot(i,:) = (invJ * xdot)';                             % Solving the RMRC equation
                qMatrix(i+1,:) = qMatrix(i,:) + deltaT * qdot(i,:); % Updating next joint state based on joint velocities
            end
        end     
        
        %% Creating the Ellipsis Around each Robot Link
        function isCollision = CheckCollision(self, model)

            isCollision = false;

            % Creating an array of 4x4 transforms relating to robot links
            linkTransforms = zeros(4,4,(self.ellipsis.n)+1);                
            linkTransforms(:,:,1) = self.ellipsis.base; % Setting first transform as the base transform

            hold on
            q = self.model.getpos();

            radii = [   0.1 0.1 0.1;
                0.1 0.1 0.25;
                0.1 0.1 0.25;
                0.075 0.075 0.075;
                0.075 0.075 0.075;
                0.075 0.075 0.075;
                0.075 0.075 0.075;
            ];
            
            % Getting the link data of the robot links
            links = self.ellipsis.links;

            for i = 1:length(links)
                L = links(1,i);
                
                current_transform = linkTransforms(:,:, i);
                
                current_transform = current_transform * trotz(q(1,i) + L.offset) * ...
                transl(0,0, L.d) * transl(L.a,0,0) * trotx(L.alpha);
                linkTransforms(:,:,i + 1) = current_transform;

                centreTr = (current_transform-linkTransforms(:,:,i))/2;

            end

            points = [model.points{1,2}(:,1), model.points{1,2}(:,2), model.points{1,2}(:,3)];
            points = points(1:3) + model.base.t(1:3)';

            for i = 1:length(links)
        
                centre = linkTransforms(:,:,i+1) + linkTransforms(:,:,i);
                centre = centre/2;
                self.linkCentres(i,1) = centre(1,4);
                self.linkCentres(i,2) = centre(2,4);
                self.linkCentres(i,3) = centre(3,4);
                [x, y, z] = ellipsoid(0, 0, 0, radii(i,1), radii(i,2), radii(i,3));
                rot = linkTransforms(1:3,1:3,i) *  (linkTransforms(1:3,1:3,i+1))';
                rot  = rot(1:3,1:3);
                original_coords = [x(:)'; y(:)'; z(:)'];
                rotated_coords = rot * original_coords;
                new_x = reshape(rotated_coords(1, :), size(x)) + self.linkCentres(i,1);
                new_y = reshape(rotated_coords(2, :), size(y)) + self.linkCentres(i,2);
                new_z = reshape(rotated_coords(3, :), size(z)) + self.linkCentres(i,3);
                % e = surf(new_x, new_y, new_z);

                 % Updating the points of the model relative to the links on the robot
                modelPointsAndOnes = (inv(linkTransforms(:,:,i)) * [points, ones(size(points,1),1)]')'; %#ok<MINV>
                updatedModelPoints = modelPointsAndOnes(:,1:3); % Getting the relative x-y-z point
                algerbraicDist = self.GetAlgebraicDist(updatedModelPoints, centre, radii(i,:));    % Checking the algerbraic distance of these points
                    
                % Checking if the model is within the light curtain (i.e. there
                % is an algerbraic distance of < 1 with any of the above points
                if(find(algerbraicDist < 1) > 0)
                    isCollision = true; % collision has been detected
                    return; % Returning on first detection of collision with object
                end
            end
        end
    end

    %% Static Methods
    methods (Static)
        %% Getter for the Algerbraic Distance between Objects and Light Curtain
        function algebraicDist = GetAlgebraicDist(points, centerPoint, radii)
            algebraicDist = ((points(:,1)-centerPoint(1))/radii(1)).^2 ...
                  + ((points(:,2)-centerPoint(2))/radii(2)).^2 ...
                  + ((points(:,3)-centerPoint(3))/radii(3)).^2;
        end
    end
end
