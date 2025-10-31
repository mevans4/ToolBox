classdef Lab4Skeleton_Question2and3 < handle
    methods
        function self = Lab4Skeleton_Question2and3()
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
            % 2.1) Load a model of the Puma 560 robot
            % mdl_puma560
            
            % 2.2) Define our first end-effector pose as a 4x4 Homogeneous Transformation Matrix
            % T1 = transl(0.5,-0.4,0.5);
            
            % 2.3) Solve the inverse kinematics to get the required joint angles
            % q1 = p560.ikine(T1);
            
            % 2.4) Define the second end-effector pose as a 4x4 Homogeneous Transformation Matrix
            % T2 = transl(___);
            
            % 2.5) Solve the inverse kinematics to get the required joint angles
            % q2 = p560.ikine(___);
        end
        
        function Question3()
            % 3.1) Options
            interpolation = 1;                                              % 1 = Quintic Polynomial, 2 = Trapezoidal Velocity
            steps = 50;                                                     % Specify no. of steps
            
            % 3.2) Load a puma560 robot, use the q1 and q2 from the previous ikine exercise
            % mdl_puma560
            % qlim = p560.qlim;
            
            % Define end-effector poses (same as Question 2)
            % T1 = transl(___);
            % q1 = p560.ikine(___);
            % T2 = transl(___);
            % q2 = p560.ikine(___);
            
            % 3.3) Generate a matrix of interpolated joint angles with 50 steps between q1 and q2
            % Use the following two methods then do steps 3.4 to 3.10 for each method
            
            % Method 1: Quintic Polynomial
            % qMatrix = jtraj(q1,q2,steps);
            
            % Method 2: Trapezoidal Velocity Profile
            % s = lspb(0,1,steps);
            % qMatrix = nan(steps,6);
            % for i = 1:steps
            %     qMatrix(i,:) = (1-s(i))*q1 + s(i)*q2;
            % end
            
            % Alternative: Use switch statement for method selection
            % switch interpolation
            %     case 1
            %         qMatrix = jtraj(___);
            %     case 2
            %         s = lspb(___);
            %         qMatrix = nan(steps,6);
            %         for i = 1:steps
            %             qMatrix(i,:) = (1-s(i))*q1 + s(i)*q2;
            %         end
            %     otherwise
            %         error('interpolation = 1 for Quintic Polynomial, or 2 for Trapezoidal Velocity')
            % end
            
            % 3.4) Animate the generated trajectory and the Puma 560 robot
            % Note how 'trail','r-' will draw a red line of the end-effector trajectory
            % figure(1)
            % p560.plot(qMatrix,'trail','r-');
            
            % 3.5) Create matrices of the joint velocities and accelerations for analysis
            % velocity = zeros(steps,6);
            % acceleration = zeros(steps,6);
            % for i = 2:steps
            %     velocity(i,:) = qMatrix(i,:) - qMatrix(i-1,:);
            %     acceleration(i,:) = velocity(i,:) - velocity(i-1,:);
            % end
            
            % 3.6) Plot the joint angles, velocities, and accelerations
            % When plotting the joint angles, use qlim to draw reference lines for upper and lower joint limits
            
            % Plot joint angles
            % figure(2)
            % for i = 1:6
            %     subplot(3,2,i)
            %     plot(qMatrix(:,i),'k','LineWidth',1)
            %     title(['Joint ', num2str(i)])
            %     xlabel('Step')
            %     ylabel('Joint Angle (rad)')
            %     refline(0,qlim(i,1))  % Reference line on the lower joint limit for joint i
            %     refline(0,qlim(i,2))  % Reference line on the upper joint limit for joint i
            % end
            
            % Plot joint velocities
            % figure(3)
            % for i = 1:6
            %     subplot(3,2,i)
            %     plot(velocity(:,i),'k','LineWidth',1)
            %     title(['Joint ', num2str(i)])
            %     xlabel('Step')
            %     ylabel('Joint Velocity')
            % end
            
            % Plot joint accelerations
            % figure(4)
            % for i = 1:6
            %     subplot(3,2,i)
            %     plot(acceleration(:,i),'k','LineWidth',1)
            %     title(['Joint ', num2str(i)])
            %     xlabel('Step')
            %     ylabel('Joint Acceleration')
            % end
            
            % 3.7) Consider the following:
            % * Joint limitations – Certain inverse kinematic solutions will give infeasible joint angles
            % * Joint velocities – appreciation for the difference between Quintic Polynomials and Trapezoidal Velocity Profiles
            % * End-effector path – The end-effector will not follow a straight line from one pose to another
        end
    end
end
