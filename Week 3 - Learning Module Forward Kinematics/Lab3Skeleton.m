classdef Lab3Skeleton < handle
    methods
        function self = Lab3Skeleton()
            close all
            set(0,'DefaultFigureWindowStyle','docked')
            clc

            % You can run these individually when ready:
            % self.Question1(0); % 3-Link Planar Robot
            % self.Question1(1); % 3-Link 3D Robot
            % self.Question1(2); % UR10 (AAN-BOT)
            % self.Question1(3); % SPIR Robot
            % self.Question1(4); % Sawyer Robot (you must create Sawyer.m)
            % self.Question2();
            % self.Question3();
        end
    end

    methods (Static)
        function Question1(modelIndex)
            % 1.1) Use the figures provided to derive the DH parameters

            % 1.2) Use the DH parameters to generate the robot model
            % link(1) = Link('d',___,'a',___,'alpha',___,'offset',___,'qlim', [__,__]);
            % ...
            % robotModel = SerialLink(link,'name','<InsertRobotName>');

            % 1.3) Use teach to manually change joint variables
            % q = zeros(1,robotModel.n);
            % robotModel.plot(q);
            % robotModel.teach(q);

            % 1.4) Get current joint angles
            % q = robotModel.getpos();

            % 1.5) Get forward kinematics T = robotModel.fkine(q)

            % 1.6) Use inverse kinematics to recover q from T (note: doesn't work for 3DOF)
            % q = robotModel.ikine(T);

            % 1.7) Get Jacobian in base frame
            % J = robotModel.jacob0(q);
            % J = J(1:3,1:3); % for 3DOF

            % 1.8) Try to invert J
            % inv(J)

            % 1.9) Try configurations where J can't be inverted
            % q = zeros(1,robotModel.n); J = robotModel.jacob0(q); inv(J)

            % 1.10) Visualise velocity ellipse
            % robotModel.vellipse(q);

            % 1.11) Try plotting ellipse for configurations with singular Jacobian
        end

        function Question2()
            % 2.1) Derive D&H parameters for the Denso VM-6083D-W

            % 2.2) Include joint limits

            % 2.3) Sample joint angles within joint limits at 30-degree increments

            % 2.4) Use fkine to determine EE positions for each pose

            % 2.5) Create 3D point cloud of the workspace
            % plot3(x,y,z,'.')
            
            % Hints:
            % - You can skip joint 6
            % - Use nested for loops to iterate q1–q5
            % - Use preallocation to speed up execution
        end

        function Question3()
            % 3.1) Create a Denso robot with object name 'densoRobot'

            % 3.2) Set q = [0, pi/2, 0, 0, 0, 0] and use fkine to get EE transform
            % blastStartTr = densoRobot.model.fkine(q).T;
            % blastStartPoint = blastStartTr(1:3,4)';

            % 3.3) Use TR * transl to get blast end point
            % blastEndTr = blastStartTr * transl(0,0,1);
            % blastEndPoint = blastEndTr(1:3,4)';

            % 3.4) Use plot3 to draw a red line between these two points

            % 3.5) Create a surface at x = 1.5
            % [Y,Z] = meshgrid(...); X = repmat(1.5,...); surf(X,Y,Z)

            % 3.6) Use LinePlaneIntersection to compute intersection
            % [intersectionPoints, check] = LinePlaneIntersection(...)

            % 3.7) Randomise joints 4–6 while keeping joints 1–3 fixed
            % - Try jtraj to create a trajectory
            % - Plot the blast stream in each step
        end
    end
end
