classdef Lab2Starter < handle

methods (Static)
    % Doing transformation (translation and rotation)
    function RunPart1()
        clf; % Clear the figure in focus or create one
        clc; % Clear all the text in the command window

        %% Transform 1
        T1 = SE2(1, 2, 30*pi/180) %#ok<NOPRT>
        T1_h = trplot2(T1, 'frame', '1', 'color', 'b');        
        pause
        axis equal;
        pause

        %% Transform 2
        T2 = SE2(2, 1, 0) %#ok<NOPRT>
        hold on
        T2_h = trplot2(T2, 'frame', '2', 'color', 'r');
        pause

        %% Transform 3 is T1*T2
        T3 = T1 * T2 %#ok<NOPRT>
        T3_h = trplot2(T3, 'frame', '3', 'color', 'g');        
        pause
        
        %% Transform 4 is T2*T1
        T4 = T2*T1
        T4_h =trplot2(T4, 'frame', '4', 'color', 'k');
        pause

        %% Set up the Axis so we can see everything
        axis([0 5 0 5]);
        axis equal;
        grid on;
        pause

        %% What is the transform T5 between T3 and T4 (i.e. how can you transform T3 to be T4)?
        T5 = inv(T3) * T4; 
        % Since
        T3 * inv(T3) * T4 - T4 == 0
        pause

        %% Transform from transform to point
        P = [3 ; 2 ];
        plot_point(P, '*');
       
        % When multiplying an SE2 object by another vector/matrix,
        % we need the double version accessed through the .T operator.
        P1 = inv(T1).T * [P; 1];
        h2e( inv(T1).T * e2h(P) )
        % More compact
        homtrans( inv(T1).T, P)

        % In respect to T2
        P2 = homtrans( inv(T2).T, P)
        pause
        
        %% Page 27
        clf
        
        R = rotx(pi/2)
        disp('%% Page 27'); 
        
        % Show the trplot as 'rviz'
        R_h = trplot(R,'frame','1', 'rgb','rviz')
        pause
        delete(R_h);
        
        % Show the trplot as 'arrow'
        R_h = trplot(R,'frame','1', 'rgb','arrow')
        axis equal;
        grid on;
        pause
        % Incrementing by 1 deg 
        for i = 1:90
            try delete(R_h); end %#ok<TRYNC>
            R = R * rotx(pi/180)
            R_h = trplot(R,'frame','1', 'rgb','arrow');
            drawnow();
            pause(0.01);
        end
        pause
        
        %% Creating a new one from scratch
        for i = 1:2:90    
            try delete(R_h); end %#ok<TRYNC>
            R = rotx(i * pi/180)
            R_h = trplot(R,'frame','1', 'rgb','arrow');
            drawnow();
        %     pause(0.01);
        end
        pause

        %% Rotate back and forwards around each of the 3 axes
        % Incrementing by 1 deg 
        R = eye(3);
        rotationAxis = 2;
        for i = [0:2:90, 89:-2:0]
            try delete(R_h); end %#ok<TRYNC>

            if rotationAxis == 1 % X axis rotation
                R = rotx(i * pi/180);
            elseif rotationAxis == 2 % Y axis rotation
                R = roty(i * pi/180);
            else % rotationAxis ==3 % Z axis rotation
                R = rotz(i * pi/180);
            end

            R_h = trplot(R,'frame','1', 'rgb','arrow');
            drawnow();
            pause(0.01);
        end
        pause

        %% Rotate all 3 axis at the same time
        cla;
        axis([-2,2,-2,2,-2,2]);hold on
        R = eye(3);
        for i = [0:2:90, 89:-2:0]
            try delete(R_h); end %#ok<TRYNC>
            R = rotx(i * pi/180) * roty(i * pi/180) * rotz(i * pi/180);
            R_h = trplot(R,'frame','1', 'rgb','arrow');            
            sumofAxes = R(:,1) + R(:,2) + R(:,3);
            plot3(sumofAxes(1),sumofAxes(2),sumofAxes(3),'*');
            drawnow();
            pause(0.01);
        end
        pause
        
        %% Questions: Will the plot of the sum of the axis vectors in the orientation be the same no matter the order
        % The coloured point represent the sum of the 3 axis for different
        % rotations. Which plot is which?
        % a. red,green,blue,black = Rotations orders (x,y,z),(z,y,x),(x,z,y),(z,x,y)
        % b. red,green,blue,black = Rotations orders (z,y,x),(x,z,y),(z,x,y),(x,y,z)
        % c. red,green,blue,black = Rotations orders (x,z,y),(z,x,y),(x,y,z),(z,y,x)
        % d. red,green,blue,black = Rotations orders (z,x,y),(x,y,z),(z,y,x),(x,z,y)
        cla
        axis([-2,2,-2,2,-2,2]); hold on;
        for i = [0:2:90, 89:-2:0]
            try delete(R1_h); end %#ok<TRYNC>
            try delete(R2_h); end %#ok<TRYNC>
            try delete(R3_h); end %#ok<TRYNC>
            try delete(R4_h); end %#ok<TRYNC>
            R1 = rotx(i * pi/180) * roty(i * pi/180) * rotz(i * pi/180);
            R2 = rotz(i * pi/180) * roty(i * pi/180) * rotx(i * pi/180);
            R3 = rotx(i * pi/180) * rotz(i * pi/180) * roty(i * pi/180);
            R4 = rotz(i * pi/180) * rotx(i * pi/180) * roty(i * pi/180);
            R1_h = trplot(R1,'frame','1', 'rgb','arrow');
            R2_h = trplot(R2,'frame','2', 'rgb','arrow');
            R3_h = trplot(R3,'frame','3', 'rgb','arrow');
            R4_h = trplot(R4,'frame','4', 'rgb','arrow');
            sumofAxes1 = R1(:,1) + R1(:,2) + R1(:,3);
            sumofAxes2 = R2(:,1) + R2(:,2) + R2(:,3);
            sumofAxes3 = R3(:,1) + R3(:,2) + R3(:,3);
            sumofAxes4 = R4(:,1) + R4(:,2) + R4(:,3);
            plot3(sumofAxes1(1),sumofAxes1(2),sumofAxes1(3),'r*');
            plot3(sumofAxes2(1),sumofAxes2(2),sumofAxes2(3),'g*');
            plot3(sumofAxes3(1),sumofAxes3(2),sumofAxes3(3),'b*');
            plot3(sumofAxes4(1),sumofAxes4(2),sumofAxes4(3),'k*');
            drawnow();
        end
    end
    
    %% Using tranimate to plot frames changing
    function RunPart2()
        clf;
        
        trOrigin = eye(4);
        
        rotateAroundXBy90deg = trotx(pi/2);        
        tranimate(trOrigin,rotateAroundXBy90deg)        
        tranimate(rotateAroundXBy90deg,trOrigin)
        
        rotateAroundYBy90deg = troty(pi/2);        
        tranimate(trOrigin,rotateAroundYBy90deg)
        tranimate(rotateAroundYBy90deg,trOrigin)
                
        tr1 = transl(0,0,5);
        tranimate(trOrigin,tr1)        
        tr2 = transl(5,5,5)* trotx(pi/4);
        tranimate(tr1,tr2)

        disp('Please press Enter to continue');
        pause();
        
        % Now start with an axis and hold on and see the difference
        clf;
        axis([0,10,0,10,0,10],'square');
        grid on;
        hold on
        
        tr1 = transl(0,0,5);
        tranimate(trOrigin,tr1)        
        tr2 = transl(5,5,5)* trotx(pi/4);
        tranimate(tr1,tr2)
    end
        
    
    %% Create a 2 Dof robot, plot at extremities and move the joints using teach
    function RunPart3()
        clf
        L1 = Link('d',0,'a',1.5,'alpha',0,'offset',0,'qlim', [-pi/2,pi/2]);
        L2 = Link('d',0,'a',0.5,'alpha',0,'offset',0,'qlim', [-pi/4,pi/4]);
        robot = SerialLink([L1 L2],'name','RunPart3Robot');
        q = zeros(1,2); % Joints at zero position.
        workspace = [-3 3 -3 3 0 1];
        scale = 1.5;
        robot.plot(q,'workspace',workspace,'scale',scale);
        
        disp('Please press Enter to continue');
        pause();
        
        disp('The qlim in radians is [minQ1, maxQ1; minQ2, maxQ2]');
        qlim = robot.qlim
        % Note: Changed this to plot the robot at its minimum qlim
        % vs qlim(1,:) which plotted at q1_min, q1_max
        robot.plot(qlim(:,1)')
        robot.teach;
        
        display('Play with teach and then please press Enter to finish');
        pause();
        clf % This will clear the figure and remove the teach panel
    end 
end

    %% Simple Handle-type Class Example
    % Create the base class from the workspace
    %{ 
        obj = Lab2Starter;
    %}
    % Run this simple method which shows the values of the properties
    %{ 
        obj.ShowValues();
    %}
    % Get the values of the properties
    %{
    	obj.classProperty1
        obj.classProperty2
        obj.classProperty3
    %}
    % Change the values of the properties
    %{
        obj.classProperty1 = obj.classProperty1 + 1;
        obj.classProperty2 = 'b'
        obj.classProperty3 = plot(rand(100,1),'r.')
    %}
    % Get the values of the properties and see how they have changed
    %{ 
        obj.classProperty1
        obj.classProperty2
        obj.classProperty3
    %}
    % Delete the plot from the current axis
    %{ 
        delete(obj.classProperty3)
    %}
    % Run this simple method which shows the values of the properties
    %{ 
        obj.ChangeValues();
    %}
properties
    classProperty1 = 1;
    classProperty2 = 'a';
    classProperty3;
end

methods
    function self = Lab2Starter()
        disp('This is the constructor and does not really need to be here if it does nothing like this')
    end
    
    function ShowValues(self)
        self.classProperty1
        self.classProperty2
        self.classProperty3        
    end
    
    function ChangeValues(self)
        self.classProperty1 = self.classProperty1 + 1;
        self.classProperty2 = char(self.classProperty2 + 1);
        try delete(self.classProperty3); end %#ok<TRYNC>
        self.classProperty3 = [];       
    end
end

end
        
