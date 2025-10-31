classdef Lab1KeyboardControlExtension < handle
    properties (Constant)
        %> Cars' start transforms
        car1TrStart = SE2(300, 540, 0).T;
        car2TrStart = SE2(300, 100, 0).T;

        %> Constant parameters
        carMoveForward = 10;
        carMoveBackward = -5;
        carTurnDegrees = 3;
    end

    properties
        %> Handles
        text_h = [];
        car1_h = [];
        car2_h = [];

        %> Transform containers
        car1Tr = Lab1KeyboardControlExtension.car1TrStart;
        car2Tr = Lab1KeyboardControlExtension.car2TrStart;

        %> Variable parameters
        speedMultiplier = 1;
        crashCounter = 0;

        %> Car images
        rgbImageRedCar;
        rgbImageBlueCar
    end

    methods
%% Lab1KeyboardControlExtension        
        function self = Lab1KeyboardControlExtension()
            close all;
            
            set(gcf,'Name','Bonus Question')
            imshow('Lab1CircularRaceTrack.jpg');
            axis on
            hold on;                      
            
            self.rgbImageRedCar = imread('RedCarSmall.png'); % You need to download this file from Canvas
            hold on;
            self.car1_h = imshow(self.rgbImageRedCar);
            
            self.rgbImageBlueCar = imread('BlueCarSmall.png'); % You need to download this file from Canvas
            hold on;
            self.car2_h = imshow(self.rgbImageBlueCar);
            
            self.crashCounter = 0;
            self.speedMultiplier = 1;

            self.RestartCars();
            
            h = gcf;
            set(h,'WindowKeyReleaseFcn',@self.move_Callback);
            set(h,'WindowKeyPressFcn',@self.move_Callback)
        end

%% UpdateMessage
        function UpdateMessage(self)
            try delete(self.text_h);end %#ok<TRYNC>
            message = sprintf(['Crash Count: ',num2str(self.crashCounter),'\n'...
                               'Speed x:',num2str(round(self.speedMultiplier,2))]);
            self.text_h = text(10, 50, message, 'FontSize', 20, 'Color', [.6 .2 .6]);
        end

%% move_Callback
        function move_Callback(self,hObject, eventdata, handles) %#ok<INUSD> 
            display(eventdata.Key);
            switch eventdata.Key 
                case 'uparrow'
                    self.car1Tr = self.car1Tr * SE2(self.carMoveForward * self.speedMultiplier, 0, 0).T;
                    self.UpdateCar('red','move');
            
                case 'downarrow'
                    self.car1Tr = self.car1Tr * SE2(self.carMoveBackward * self.speedMultiplier, 0, 0).T;
                    self.UpdateCar('red','move');        
            
                case 'leftarrow'
                    self.car1Tr = self.car1Tr * SE2(0,0,deg2rad(-self.carTurnDegrees)).T;
                    self.UpdateCar('red','rotate');
            
                case 'rightarrow'
                    self.car1Tr = self.car1Tr * SE2(0,0,deg2rad(self.carTurnDegrees)).T;
                    self.UpdateCar('red','rotate');
            
                case 'w'
                    self.car2Tr = self.car2Tr * SE2(self.carMoveForward * self.speedMultiplier, 0, 0).T;
                    self.UpdateCar('blue','move');
            
                case 's'
                    self.car2Tr = self.car2Tr * SE2(self.carMoveBackward * self.speedMultiplier, 0, 0).T;
                    self.UpdateCar('blue','move');
            
                case 'a'
                    self.car2Tr = self.car2Tr * SE2(0,0,deg2rad(-self.carTurnDegrees)).T;
                    self.UpdateCar('blue','rotate');
            
                case 'd'
                    self.car2Tr = self.car2Tr * SE2(0,0,deg2rad(self.carTurnDegrees)).T;
                    self.UpdateCar('blue','rotate');      
            
                case 'space'        
                    self.RestartCars;
    
                case 'add'        
                    self.speedMultiplier = self.speedMultiplier * 1.05;
                    self.UpdateMessage();

                case 'subtract'        
                    self.speedMultiplier = self.speedMultiplier * 0.95 ;       
                    self.UpdateMessage();
            end    
        
            if self.CheckCrash()
                self.crashCounter = self.crashCounter + 1;
                self.RestartCars();
            end
        
        end

%% RestartCars
        function RestartCars(self)
            self.car1Tr = self.car1TrStart;
            self.car2Tr = self.car2TrStart;
            self.UpdateAllCars();
            self.UpdateMessage();
        end

%% UpdateAllCars
        function result = CheckCrash(self)
            result = abs(self.car1Tr(1,3)-self.car2Tr(1,3))<50 ...
                  && abs(self.car1Tr(2,3)-self.car2Tr(2,3))<50;
        end

%% UpdateAllCars
            function UpdateAllCars(self)
                self.UpdateCar('red','move');
                self.UpdateCar('red','rotate');
                self.UpdateCar('blue','move');
                self.UpdateCar('blue','rotate');
            end

%% UpdateCar
        function UpdateCar(self,car,action)
            if strcmp(car,'red')
                self.car1_h = self.TransformCarAction(action,self.car1_h,self.car1Tr,self.rgbImageRedCar);  
            elseif strcmp(car,'blue')
                self.car2_h = self.TransformCarAction(action,self.car2_h,self.car2Tr,self.rgbImageBlueCar);
            end
        end
    end

    methods (Static)
%% TransformCarAction        
        function car_h = TransformCarAction(action,car_h,carTr,rgbImageOfCar)
            if strcmp(action,'rotate')
                rpy = tr2rpy(carTr);
                % Not a good way since it adds black background, it's better to do it with objects
                car_h.CData = imrotate(rgbImageOfCar,-rad2deg(rpy(3))); % Note the image rotates in the opposite direction
            elseif strcmp(action,'move')                
                xSize = car_h.XData(2) - car_h.XData(1);
                ySize = car_h.YData(2) - car_h.YData(1);
                car_h.XData = [carTr(1,3), carTr(1,3) + xSize];
                car_h.YData = [carTr(2,3), carTr(2,3) + ySize];
            end
        end
    end
end