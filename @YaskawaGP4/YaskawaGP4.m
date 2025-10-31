classdef YaskawaGP4 < RobotBaseClass
    %% Yaskawa GP4 Robot

    properties(Access = public)
        plyFileNameStem = 'yaskawaGP4';
    end

    methods
        %% Define robot Function
        function self = YaskawaGP4(baseTr)
            self.CreateModel();
            if nargin < 1
                baseTr = transl(0.8,0.10,0.76);

            end
            self.model.base = self.model.base.T * baseTr * trotz(pi);
            self.PlotAndColourRobot();

        end


        %% Create the robot model
        function CreateModel(self)
            link(1) = Link('d',0.330,'a',0,'alpha', pi/2, 'offset',0); % 165mm from the base TR
            link(2) = Link('d',0,'a',0.260,'alpha', 0, 'offset',pi/2); % 165mm from the joint 1 TR
            link(3) = Link('d',0,'a',-0.015,'alpha', -pi/2, 'offset',pi);
            link(4) = Link('d',-0.290,'a',0,'alpha', -pi/2, 'offset',0); 
            link(5) = Link('d',0,'a', 0,'alpha', pi/2, 'offset', 0); % .1945
            link(6) = Link('d',-0.072,'a', 0,'alpha', pi, 'offset',pi); % .0625

            % Incorporate joint limits
            link(1).qlim = [-170 170]*pi/180;
            link(2).qlim = [-110 130]*pi/180;
            link(3).qlim = [-200 65]*pi/180; %% qlinm reversed to work properly
            link(4).qlim = [-200 200]*pi/180;
            link(5).qlim = [-123 123]*pi/180;
            link(6).qlim = [-455 455]*pi/180;

            self.model = SerialLink(link,'name',self.name);
            

        end

    end
end