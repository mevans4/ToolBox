classdef KukaKr3R540 < RobotBaseClass
    %% KUKA KR3 R540 payload robot model
    %
    % WARNING: This model has been created by UTS students in the subject
    % 41013. No guarentee is made about the accuracy or correctness of the
    % of the DH parameters of the accompanying ply files. Do not assume
    % that this matches the real robot!

    properties(Access = public)   
        plyFileNameStem = 'KukaKr3R540';
    end
    
    methods
%% Constructor
        function self = KukaKr3R540(baseTr,useTool,toolFilename)
            if nargin < 3
                if nargin == 2
                    error('If you set useTool you must pass in the toolFilename as well');
                elseif nargin == 0 % Nothing passed
                    baseTr = transl(0,0,0);  
                end             
            else % All passed in 
                self.useTool = useTool;
                toolTrData = load([toolFilename,'.mat']);
                self.toolTr = toolTrData.tool;
                self.toolFilename = [toolFilename,'.ply'];
            end
          
            self.homeQ = [-1.5708,-0.8659,0.8196,-1.7454,-1.6171,0.4636];
            self.CreateModel();
			self.model.base = self.model.base.T * baseTr;
            self.model.tool = self.toolTr;
            self.PlotAndColourRobot();

            drawnow
        end

%% CreateModel
        function CreateModel(self)
            link(1) = Link('d',0.345,'a', 0.020, 'alpha',-pi/2, 'offset',      pi/2, 'qlim',[-170*pi/180 170*pi/180]);
            link(2) = Link('d',    0,'a',-0.260, 'alpha',    0, 'offset',        pi, 'qlim',[-170*pi/180  50*pi/180]);
            link(3) = Link('d',    0,'a',-0.020, 'alpha', pi/2, 'offset',     -pi/2, 'qlim',[-110*pi/180 155*pi/180]);
            link(4) = Link('d',0.260,'a',     0, 'alpha',-pi/2, 'offset',-80*pi/180, 'qlim',[-175*pi/180 175*pi/180]);
            link(5) = Link('d',    0,'a',     0, 'alpha', pi/2, 'offset',         0, 'qlim',[-120*pi/180 120*pi/180]);
            link(6) = Link('d',0.075,'a',     0, 'alpha',   pi, 'offset',        pi, 'qlim',[-350*pi/180 350*pi/180]);
             
            self.model = SerialLink(link,'name',self.name);
        end      
    end
end
