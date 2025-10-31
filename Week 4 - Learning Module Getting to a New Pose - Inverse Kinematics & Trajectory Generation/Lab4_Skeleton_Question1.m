classdef Lab4Skeleton < handle
    methods
        function self = Lab4Skeleton()
            close all
            set(0,'DefaultFigureWindowStyle','docked')
            clc

            % You can run these individually when ready:
            % self.Question1();
        end
    end

    methods (Static)
        function Question1()
            clf
            
            % 1.1) Make the 3DOF planar arm model
            % L1 = Link('d',___,'a',___,'alpha',___,'qlim',[___]);
            % L2 = Link('d',___,'a',___,'alpha',___,'qlim',[___]);
            % L3 = Link('d',___,'a',___,'alpha',___,'qlim',[___]);
            % robot = SerialLink([L1 L2 L3],'name','myRobot');
            
            % 1.2) Rotate the base around the Y axis so the Z axis faces downways
            % robot.base = troty(___);
            
            % 1.3) Set workspace, scale and initial joint state, then plot and teach
            % q = zeros(1,___);
            % robot.plot(q,'workspace',[___],'scale',___);
            % robot.teach;
            
            % 1.4) Move the robot around with "teach" and observe that there is no way to affect the Z, roll or pitch values, no matter what joint value you choose.
            
            % 1.5) Consider a pen that is mounted to the Z-axis of the final joint. Note how this means we don't care about the yaw angle (if it's a pen where the Z axis is rotating, it doesn't affect the drawing result).
            
            % 1.6) Get a solution for the end effector at [-0.75,-0.5,0], and make sure you mask out the impossible-to-alter values (i.e. z, roll and pitch) and the value we don't care about (i.e. yaw). Thus we need a mask of [1,1,0,0,0,0]:
            % newQ = robot.ikine(transl(___), 'q0', ___, 'mask', [___]);
            
            % 1.7) Plot the new joint state and check how close it got to the [x, y] in the goal transform
            % robot.plot(___);
            % robot.fkine(___);
            
            % Add a plotting trail for visualization
            % rh = findobj('Tag', robot.name); ud = rh.UserData; hold on; ud.trail = plot(0,0,'-'); set(rh,'UserData',ud);
            
            % 1.8) Go through a loop using the previous joint as the guess to draw a line from [-0.75,-0.5,0] to [-0.75,0.5,0] and animate each new joint state trajectory
            % for y = ___:___:___
            %     newQ = robot.ikine(transl(___), 'q0', ___, 'mask', [1,1,0,0,0,0]);
            %     robot.animate(___);
            %     drawnow();
            % end
            
            disp('Press enter to continue');
            pause;
            
            % 1.9) Instead of trusting "animate", do your own interpolation between joint states and keep track of the [x,y] location of points using fkine. How straight is the actual line drawn if you see every point in between?
            
            % 1.10) Using ikine to get the newQ and fkine to determine the actual point, and animate to move the robot to "draw" a circle around the robot with a radius of 0.5m
            hold on;
            % plot(___,'r.')
            % for circleHalf = 1:2
            %     for x = ___:___:___
            %         if circleHalf == 1
            %             y = sqrt(0.5^2-x^2);
            %         else
            %             x = -x;
            %             y = -sqrt(0.5^2-x^2);
            %         end
            %         plot(x,y,'r.');
            %         newQ = robot.ikine(transl(___), 'q0', ___, 'mask', [1,1,0,0,0,0]);
            %         robot.animate(___);
            %         drawnow();
            %     end
            % end
            
            % 1.11) Add a pen and make the axis equal. Get the vertices out of the mesh handle for use later
            % mesh_h = PlaceObject(___);
            % axis equal
            % vertices = get(mesh_h,___);
            
            % 1.12) Translate the vertices of this pen by 0.1m in the z-axis
            % transformedVertices = [vertices,ones(size(vertices,1),1)] * transl(___)';
            % set(mesh_h,'Vertices',transformedVertices(:,___));
            
            % 1.13) Change the orientation of the vertices by pi/2 radians about the x-axis
            % transformedVertices = [vertices,ones(size(vertices,1),1)] * trotx(___)';
            % set(mesh_h,'Vertices',transformedVertices(:,___));
            
            % 1.14) Use a 3-link planar robot from the toolbox, and move the pen as if it were on the end-effector through a naively-created arm trajectory
            % mdl_planar3
            % hold on
            % p3.plot([0,0,0])
            % p3.delay = 0;
            % 
            % axis([-3,3,-3,3,-0.5,8])
            % 
            % for i = -pi/4:0.01:pi/4
            %     p3.animate([___]);
            %     tr = p3.fkine([___]);
            %     transformedVertices = [vertices,ones(size(vertices,1),1)] * tr.T';
            %     set(mesh_h,'Vertices',transformedVertices(:,___));
            %     drawnow();
            %     pause(0.01);
            % end
            
            % Note: Various ways to correctly transform a point cloud:
            % transformedVertices = [vertices,ones(size(vertices,1),1)] * tr';
            % transformedVertices = [tr * [vertices,ones(size(vertices,1),1)]']';
            % transformedVertices = [tr(1:3,1:3) * vertices(:,1:3)' + tr(1:3,4)]';
        end
    end
end
