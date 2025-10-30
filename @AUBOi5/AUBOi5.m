classdef AUBOi5 < RobotBaseClass
    %% AUBO i5 Robot
    % https://www.aubo-cobot.com/public/i5product3?CPID=i5
    
    properties(Access = public)
        plyFileNameStem = 'AUBOi5';
    end
    
    methods
        %% Constructor
        function self = AUBOi5(baseTr)
            self.CreateModel();
            if nargin < 1
                baseTr = eye(4);
            end
            self.model.base = self.model.base.T * baseTr;
            self.PlotAndColourRobot();
        end
        
        %% Create the robot model
        function CreateModel(self)
            % D&H parameters for the AUBO i5 model
            % DH = [THETA D A ALPHA SIGMA OFFSET]
            link(1) = Link('d', 0.1220, 'a', 0,      'alpha', pi/2, 'offset', 0);
            link(2) = Link('d', 0,      'a', 0.4080, 'alpha', 0,    'offset', 0);
            link(3) = Link('d', 0,      'a', 0.3760, 'alpha', 0,    'offset', 0);
            link(4) = Link('d',-0.1215, 'a', 0,      'alpha', pi/2, 'offset', 0);
            link(5) = Link('d', 0.1025, 'a', 0,      'alpha', pi/2, 'offset', 0);
            link(6) = Link('d', 0.0940, 'a', 0,      'alpha', 0,    'offset', 0);
            
            % Incorporate joint limits
            link(1).qlim = [-90  90] * pi/180;
            link(2).qlim = [5   175] * pi/180;
            link(3).qlim = [-175  175] * pi/180;
            link(4).qlim = [-360  360] * pi/180;
            link(5).qlim = [-360  360] * pi/180;
            link(6).qlim = [-360  360] * pi/180;
            
            self.model = SerialLink(link, 'name', self.name);
        end
    end
end