classdef Lab5_Question1_Skeleton < handle
    methods
        function self = Lab5_Question1_Skeleton()
            close all
            set(0,'DefaultFigureWindowStyle','docked')
            clc

            % Run Question 1
            self.Question1();
        end
    end

    methods (Static)
        function Question1()
            % 1) Help the Robot Blaster save the Planet from UFOs!
            clf
            
            % 1.1) Make sure you have a way to check each of the cone end rays for intersection with a UFO
            % (CheckIntersections.m and check_intersections function inside UFOFleet.py)
            
            % 1.2) Create and plot a UFO Fleet of 10 ships
            ufoFleet = UFOFleet(10);
            
            % 1.3) Create the blaster robot. Note this is the actual "Grit Blasting" robot working on the Sydney Harbor Bridge
            blasterRobot = SchunkUTSv2();
            plot3d(blasterRobot.model,zeros(1,6));
            endEffectorTr = blasterRobot.model.fkine(zeros(1,6)).T;
            
            % 1.4) Now plot a "blast" cone coming out of the end effector (assume it is the Z-axis of the end effector.
            [X,Y,Z] = cylinder([0,0.1],6);
            Z = Z * 10;
            updatedConePoints = [endEffectorTr * [X(:),Y(:),Z(:),ones(numel(X),1)]']';
            conePointsSize = size(X);
            cone_h = surf(reshape(updatedConePoints(:,1),conePointsSize) ...
                         ,reshape(updatedConePoints(:,2),conePointsSize) ...
                         ,reshape(updatedConePoints(:,3),conePointsSize));
            view(3);
            
            % 1.5) Now plot a "scoreboard"
            currentScore = 0;
            scoreZ = ufoFleet.workspaceDimensions(end)*1.2;
            text_h = text(0, 0, scoreZ,sprintf('Score: 0 after 0 seconds'), 'FontSize', 10, 'Color', [.6 .2 .6]);
            
            % 1.6) Add the following "while loop" to iteratively call your function
            tic;
            % Go through iterations of randomly move UFOs, then move robot. Check for hits and update score and timer
            while ~isempty(find(0 < ufoFleet.healthRemaining,1))
               ufoFleet.PlotSingleRandomStep();
               % Get the goal joint state 
               goalJointState = GetGoalJointState(blasterRobot,ufoFleet);

               % Fix goal pose back to a small step away from the min/max joint limits
               fixIndexMin = goalJointState' < blasterRobot.model.qlim(:,1);
               goalJointState(fixIndexMin) = blasterRobot.model.qlim(fixIndexMin,1) + 10*pi/180;
               fixIndexMax = blasterRobot.model.qlim(:,2) < goalJointState';
               goalJointState(fixIndexMax) = blasterRobot.model.qlim(fixIndexMax,2) - 10*pi/180;

               % Get a trajectory
               jointTrajectory = jtraj(blasterRobot.model.getpos(),goalJointState,8);
               for armMoveIndex = 1:size(jointTrajectory,1)
                  animate(blasterRobot.model,jointTrajectory(armMoveIndex,:));
                  
                  endEffectorTr = blasterRobot.model.fkine(jointTrajectory(armMoveIndex,:)).T;
                  updatedConePoints = [endEffectorTr * [X(:),Y(:),Z(:),ones(numel(X),1)]']';
                  set(cone_h,'XData',reshape(updatedConePoints(:,1),conePointsSize) ...
                            ,'YData',reshape(updatedConePoints(:,2),conePointsSize) ...
                            ,'ZData',reshape(updatedConePoints(:,3),conePointsSize));

                  coneEnds = [cone_h.XData(2,:)', cone_h.YData(2,:)', cone_h.ZData(2,:)'];
                  ufoHitIndex = CheckIntersections(endEffectorTr,coneEnds,ufoFleet);
                  ufoFleet.SetHit(ufoHitIndex);
                  currentScore = currentScore + length(ufoHitIndex);

                  text_h.String = sprintf(['Score: ',num2str(currentScore),' after ',num2str(toc),' seconds']);
                  axis([-6,6,-6,6,0,10]);
                  % Only plot every 3rd to make it faster
                  if mod(armMoveIndex,3) == 0
                     drawnow();
                  end
               end
               drawnow();
            end
            
            % 1.7) Create a file called "GetGoalJointState.m" which is called by the highlighted line above. 
            % The function must take the parameters "blasterRobot" and "ufoFleet" and use these to determine and return "goalJointState"
            
            % 1.8) One solution to put in a function GetGoalJointState.m that randomly picks a pose is defined at the bottom of this skeleton. 
            % Implement it and observe how it functions. After running it 200 times the results were as follows: Average time = 463 secs, Average score = 224 points.
            
            % 1.9) Write a better solution that uses ikine or ikcon like in earlier exercises, such that you get 
            % consistently faster (and higher scoring) results than the above random method.
        end
    end
end

%% 1.8)
function goalJointState = GetGoalJointState(blasterRobot, ufoFleet)
    %% GetGoalJointState - Determines the goal joint state for the blaster robot
    %%
    %% This function takes the blaster robot and UFO fleet as inputs and
    %% returns a goal joint state for the robot to move to.
    %%
    %% Inputs:
    %%   blasterRobot - The robot object (e.g. SchunkUTSv2)
    %%   ufoFleet - The UFO fleet object containing UFO positions and states
    %%
    %% Outputs:
    %%   goalJointState - A 1x6 vector of joint angles for the robot
    
    %% Random solution approach (from section 1.8)
    %% 1. Generate a random joint state within +/- 20 degrees of current position
    %goalJointState = blasterRobot.model.getpos() + (rand(1,6)-0.5) * 20*pi/180;
    
    %% 2. Calculate the end effector transform for this joint state
    %endEffectorTr = blasterRobot.model.fkine(goalJointState).T;
    
    %% 3. Ensure the Z component of the Z axis is positive (pointing upwards) and the Z component of the point is above 1 (approx mid height)
    %while endEffectorTr(3,3) < 0.1 || endEffectorTr(3,4) < 1
    %    goalJointState = blasterRobot.model.getpos() + (rand(1,6)-0.5) * 20*pi/180;
    %    endEffectorTr = blasterRobot.model.fkine(goalJointState).T;
    %    display('trying again');
    %end
    
    %% TODO: Replace this random method with a better solution using ikine or ikcon
    %% that targets UFO positions more effectively for higher scores and faster completion
    
end
