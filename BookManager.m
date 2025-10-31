classdef BookManager < handle
    %BOOKMANAGER Tracks book locations and colour-based stacks for the workspace

    properties
        bookHeight = 0.079;              % nominal single book height
        originalBookHandles cell = {};   % descriptors for discovered books
        currentBookIndex double = 1;     % index of next book to process
        booksPlaced double = 0;          % running count during UR3 sorting

        colorStackBases struct            % base XYZ for each colour stack
        colorStackCounts struct           % number of books placed on each colour stack
        colorStackRecords struct          % recorded placements for each colour stack

        robotDeliveryBases struct         % base XYZ for each robot's delivery pile
        robotDeliveryCounts struct        % book count delivered per robot
        deliveryLog cell = {};            % chronological log of deliveries
    end

    methods
        function self = BookManager()
            % Constructor prepares default stack and delivery locations.
            defaultStackHeight = self.bookHeight - 0.05;

            self.colorStackBases = struct( ...
                'green', [0.45, -0.525, defaultStackHeight], ...
                'blue',  [0.15, -0.525, defaultStackHeight], ...
                'red',   [-0.15, -0.525, defaultStackHeight]);

            self.robotDeliveryBases = struct( ...
                'Motoman', [0.85, 1.05, defaultStackHeight], ...
                'Kuka',    [-0.85, -1.05, defaultStackHeight], ...
                'Aubo',    [1.35, -0.25, defaultStackHeight]);

            self.reset();
        end

        function reset(self)
            %RESET Clears dynamic state ready for a fresh run
            self.originalBookHandles = {};
            self.currentBookIndex = 1;
            self.booksPlaced = 0;

            self.colorStackCounts = struct('green', 0, 'blue', 0, 'red', 0);
            emptyRecord = struct('handle', {}, 'color', {}, 'position', {}, ...
                                 'topSurface', {}, 'originalVerts', {}, 'height', {});
            self.colorStackRecords = struct('green', emptyRecord, ...
                                            'blue', emptyRecord, ...
                                            'red', emptyRecord);

            self.robotDeliveryCounts = struct('Motoman', 0, 'Kuka', 0, 'Aubo', 0);
            self.deliveryLog = {};
        end

        function storeBookHandles(self)
            %STOREBOOKHANDLES Discover current book meshes in the workspace.
            fprintf('Setting up book positions...\n');

            allPatches = findobj('Type', 'patch');
            detectedBooks = {};

            for idx = 1:numel(allPatches)
                patchHandle = allPatches(idx);
                verts = get(patchHandle, 'Vertices');
                if isempty(verts)
                    continue;
                end

                centre = mean(verts, 1);
                inBookShelf = abs(centre(1) - (-1.75)) < 0.3;
                if ~inBookShelf
                    continue;
                end

                maxVerts = max(verts, [], 1);
                topSurface = [centre(1), centre(2), maxVerts(3)];
                colorInfo = self.captureColorInformation(patchHandle);

                detectedBooks{end+1} = struct( ...
                    'handle', patchHandle, ...
                    'position', centre, ...
                    'originalVerts', verts, ...
                    'topSurfacePosition', topSurface, ...
                    'faceColor', colorInfo.faceColor, ...
                    'colorName', colorInfo.colorName, ...
                    'sourceFile', colorInfo.sourceFile); %#ok<AGROW>
            end

            fprintf('Found %d books\n', numel(detectedBooks));
            self.matchBooksToPositions(detectedBooks);

            for i = 1:numel(self.originalBookHandles)
                info = self.originalBookHandles{i};
                fprintf('  %d. %s book at [%.3f, %.3f, %.3f]\n', ...
                    i, self.getBookColorString(info), ...
                    info.position(1), info.position(2), info.position(3));
            end
        end

        function matchBooksToPositions(self, detectedBooks)
            %MATCHBOOKSTOPOSITIONS Persist descriptors for discovered books.
            self.originalBookHandles = {};

            for idx = 1:numel(detectedBooks)
                detected = detectedBooks{idx};
                [colorName, colorIndex, colorRGB] = self.determineBookColor(detected);
                height = self.estimateBookHeight(detected);

                entry = struct( ...
                    'handle', detected.handle, ...
                    'originalVerts', detected.originalVerts, ...
                    'position', detected.position, ...
                    'topSurfacePosition', detected.topSurfacePosition, ...
                    'color', colorName, ...
                    'colorRGB', colorRGB, ...
                    'height', height);

                if ~isnan(colorIndex)
                    entry.colorIndex = colorIndex;
                end

                self.originalBookHandles{end+1} = entry; %#ok<AGROW>
            end
        end

        function [bookPos, bookColor, bookIndex, bookHandle, originalVerts, topSurface] = getNextBook(self)
            %GETNEXTBOOK Retrieve descriptor of the next book to process.
            if isempty(self.originalBookHandles) || ...
                    self.currentBookIndex > numel(self.originalBookHandles)
                bookPos = [];
                bookColor = '';
                bookIndex = 0;
                bookHandle = [];
                originalVerts = [];
                topSurface = [];
                return;
            end

            info = self.originalBookHandles{self.currentBookIndex};
            bookPos = info.position;
            bookHandle = info.handle;
            originalVerts = info.originalVerts;
            topSurface = info.topSurfacePosition;
            bookIndex = self.currentBookIndex;
            bookColor = self.getBookColorString(info);
        end

        function removeBook(self, ~, bookIndex)
            %REMOVEBOOK Advance pointer after successful pick.
            if bookIndex <= numel(self.originalBookHandles)
                self.currentBookIndex = self.currentBookIndex + 1;
            end
        end

        function targetPos = getTargetPosition(self, ~)
            %GETTARGETPOSITION Legacy helper used by historic scripts.
            pattern = [ ...
                -0.5, -0.525, self.bookHeight - 0.05; ...
                -0.5, -0.525, 2*self.bookHeight - 0.05; ...
                -0.5,  0.525, self.bookHeight - 0.05; ...
                -0.5,  0.525, 2*self.bookHeight - 0.05; ...
                 0.0,  0.0,   self.bookHeight - 0.05; ...
                 0.0,  0.0,   2*self.bookHeight - 0.05];

            idx = mod(self.booksPlaced, size(pattern, 1)) + 1;
            targetPos = pattern(idx, :);
            self.booksPlaced = self.booksPlaced + 1;
        end

        function verifyBookPositions(self)
            %VERIFYBOOKPOSITIONS Debug helper to compare stored vs real poses.
            fprintf('Checking book positions...\n');
            for idx = 1:numel(self.originalBookHandles)
                info = self.originalBookHandles{idx};
                if ~isempty(info.handle) && isgraphics(info.handle)
                    verts = get(info.handle, 'Vertices');
                    currentPos = mean(verts, 1);
                    fprintf('Book %d (%s) expected [%.3f %.3f %.3f], actual [%.3f %.3f %.3f]\n', ...
                        idx, self.getBookColorString(info), ...
                        info.position(1), info.position(2), info.position(3), ...
                        currentPos(1), currentPos(2), currentPos(3));
                else
                    fprintf('Book %d missing handle\n', idx);
                end
            end
        end

        function targetPos = getMotomanTargetPosition(~, bookIndex)
            switch bookIndex
                case 3
                    targetPos = [-0.5, 0.525, 0.005];
                case 4
                    targetPos = [-0.5, 0.525, 0.079 + 0.005];
                otherwise
                    targetPos = [];
            end
        end

        function finalPos = getMotomanFinalPosition(~, bookIndex)
            if bookIndex == 4
                finalPos = [0, 1.05, 0.079];
            else
                finalPos = [0, 1.05, 0.079 * 2];
            end
        end

        function targetPos = getColorStackPosition(self, colorIdentifier)
            if isnumeric(colorIdentifier)
                colorName = self.colorIndexToString(colorIdentifier);
            else
                colorName = lower(char(colorIdentifier));
            end

            if ~isfield(self.colorStackCounts, colorName)
                error('Unknown color stack request: %s', colorName);
            end

            level = self.colorStackCounts.(colorName);
            base = self.colorStackBases.(colorName);
            targetPos = [base(1), base(2), base(3) + level * self.bookHeight];
            self.colorStackCounts.(colorName) = level + 1;
        end

        function registerPlacedBook(self, bookHandle, colorName, finalCenter, finalVerts)
            if nargin < 5 || isempty(finalVerts)
                finalVerts = get(bookHandle, 'Vertices');
            end

            if nargin < 3 || isempty(colorName)
                colorName = 'unknown';
            end

            colorName = lower(char(colorName));
            if ~isfield(self.colorStackRecords, colorName)
                error('Unknown colour stack "%s" when registering placement.', colorName);
            end

            entry = struct();
            entry.handle = bookHandle;
            entry.color = colorName;
            entry.position = finalCenter;
            entry.originalVerts = finalVerts;
            entry.height = self.estimateBookHeightFromVertices(finalVerts);
            entry.topSurface = [finalCenter(1), finalCenter(2), max(finalVerts(:, 3))];

            records = self.colorStackRecords.(colorName);
            records(end+1) = entry; %#ok<AGROW>
            self.colorStackRecords.(colorName) = records;
        end

        function entry = popBookFromColorStack(self, colorName)
            if nargin < 2 || isempty(colorName)
                entry = [];
                return;
            end

            colorName = lower(char(colorName));
            if ~isfield(self.colorStackRecords, colorName)
                entry = [];
                return;
            end

            records = self.colorStackRecords.(colorName);
            if isempty(records)
                entry = [];
                return;
            end

            tops = arrayfun(@(r) r.topSurface(3), records);
            [~, idx] = max(tops);
            entry = records(idx);
            records(idx) = [];
            self.colorStackRecords.(colorName) = records;
        end

        function pushBookBack(self, colorName, entry)
            if isempty(entry)
                return;
            end

            colorName = lower(char(colorName));
            if ~isfield(self.colorStackRecords, colorName)
                return;
            end

            records = self.colorStackRecords.(colorName);
            records(end+1) = entry; %#ok<AGROW>
            self.colorStackRecords.(colorName) = records;
        end

        function count = getColorStackSize(self, colorName)
            colorName = lower(char(colorName));
            if ~isfield(self.colorStackRecords, colorName)
                count = 0;
                return;
            end
            count = numel(self.colorStackRecords.(colorName));
        end

        function targetPos = getRobotDeliveryPosition(self, robotKey)
            if nargin < 2 || isempty(robotKey)
                error('Robot identifier required for delivery position lookup.');
            end

            if isstring(robotKey)
                robotKey = char(robotKey);
            end

            robotField = matlab.lang.makeValidName(robotKey);
            if ~isfield(self.robotDeliveryBases, robotField)
                error('Unknown robot delivery zone "%s".', robotKey);
            end

            base = self.robotDeliveryBases.(robotField);
            level = self.robotDeliveryCounts.(robotField);
            targetPos = [base(1), base(2), base(3) + level * self.bookHeight];
        end

        function registerDeliveryPlacement(self, robotKey, colorName, finalCenter, bookHandle)
            if nargin < 4
                finalCenter = [NaN, NaN, NaN];
            end

            logEntry = struct( ...
                'robot', char(robotKey), ...
                'color', char(colorName), ...
                'position', finalCenter, ...
                'timestamp', datetime('now'), ...
                'handle', []);

            if nargin >= 5
                logEntry.handle = bookHandle;
            end

            self.deliveryLog{end+1} = logEntry; %#ok<AGROW>

            robotField = matlab.lang.makeValidName(robotKey);
            if isfield(self.robotDeliveryCounts, robotField)
                self.robotDeliveryCounts.(robotField) = self.robotDeliveryCounts.(robotField) + 1;
            end
        end

        function colorStr = getBookColorString(~, info)
            if isfield(info, 'color') && ~isempty(info.color)
                colorStr = char(info.color);
            elseif isfield(info, 'colorIndex')
                colorStr = BookManager.colorIndexToString(info.colorIndex);
            else
                colorStr = 'unknown';
            end
        end

        function [colorName, colorIndex, colorRGB] = determineBookColor(self, detected)
            [colorRGB, explicitName] = self.extractColorData(detected);

            if ~isempty(explicitName)
                colorName = lower(char(explicitName));
                colorIndex = BookManager.colorStringToIndex(colorName);
                if isnan(colorIndex)
                    [mappedName, mappedIndex] = self.mapRgbToKnownColor(colorRGB);
                    if ~strcmp(mappedName, 'unknown')
                        colorName = mappedName;
                        colorIndex = mappedIndex;
                    end
                end
            else
                [colorName, colorIndex] = self.mapRgbToKnownColor(colorRGB);
            end

            if isempty(colorName)
                colorName = 'unknown';
            end

            if all(isnan(colorRGB))
                colorRGB = [];
            end
        end

        function [rgb, explicitName] = extractColorData(self, detected)
            rgb = [NaN, NaN, NaN];
            explicitName = '';

            if isfield(detected, 'colorName') && ~isempty(detected.colorName)
                explicitName = lower(char(detected.colorName));
                named = BookManager.namedColorToRgb(explicitName);
                if ~isempty(named)
                    rgb = named;
                    return;
                end
            end

            if isfield(detected, 'faceColor') && ~isempty(detected.faceColor)
                rgb = double(detected.faceColor(:)');
                if numel(rgb) ~= 3
                    rgb = [NaN, NaN, NaN];
                end
            end

            if isfield(detected, 'sourceFile') && ~isempty(detected.sourceFile)
                [derivedName, derivedRgb] = self.deriveColorFromSource(detected.sourceFile);
                if ~strcmp(derivedName, 'unknown')
                    explicitName = derivedName;
                    rgb = derivedRgb;
                end
            end
        end

        function colorInfo = captureColorInformation(~, patchHandle)
            colorInfo = struct('faceColor', [], 'colorName', '', 'sourceFile', '');

            if isempty(patchHandle) || ~isgraphics(patchHandle)
                return;
            end

            faceColor = get(patchHandle, 'FaceColor');
            if ~isempty(faceColor)
                if isnumeric(faceColor) && numel(faceColor) == 3
                    colorInfo.faceColor = double(faceColor(:)');
                elseif ischar(faceColor) || (isstring(faceColor) && isscalar(faceColor))
                    colorInfo.colorName = lower(char(faceColor));
                end
            end

            userData = get(patchHandle, 'UserData');
            if ischar(userData) || (isstring(userData) && isscalar(userData))
                colorInfo.sourceFile = char(userData);
            elseif isstruct(userData)
                if isfield(userData, 'sourceFile')
                    colorInfo.sourceFile = userData.sourceFile;
                end
                if isfield(userData, 'colorName')
                    colorInfo.colorName = userData.colorName;
                end
            end
        end

        function height = estimateBookHeight(~, detected)
            height = NaN;
            if isfield(detected, 'originalVerts') && ~isempty(detected.originalVerts)
                verts = detected.originalVerts;
                try
                    minZ = min(verts(:, 3));
                    maxZ = max(verts(:, 3));
                    height = maxZ - minZ;
                catch
                    height = NaN;
                end
            end

            if isnan(height) && isfield(detected, 'topSurfacePosition') && ...
                    ~isempty(detected.topSurfacePosition)
                height = detected.topSurfacePosition(3);
            end
        end

        function height = estimateBookHeightFromVertices(~, verts)
            if isempty(verts)
                height = NaN;
                return;
            end

            try
                minZ = min(verts(:, 3));
                maxZ = max(verts(:, 3));
                height = maxZ - minZ;
            catch
                height = NaN;
            end
        end

        function [colorName, colorIndex] = mapRgbToKnownColor(~, rgb)
            if isempty(rgb) || any(isnan(rgb))
                colorName = 'unknown';
                colorIndex = NaN;
                return;
            end

            candidates = struct('green', [0, 1, 0], 'blue', [0, 0, 1], 'red', [1, 0, 0]);

            names = fieldnames(candidates);
            rgb = double(rgb(:)');
            if max(rgb) > 1
                rgb = rgb / max(rgb);
            end

            bestName = 'unknown';
            bestError = inf;
            for i = 1:numel(names)
                name = names{i};
                target = candidates.(name);
                err = norm(rgb - target);
                if err < bestError
                    bestError = err;
                    bestName = name;
                end
            end

            if bestError < 0.4
                colorName = bestName;
                colorIndex = BookManager.colorStringToIndex(bestName);
            else
                colorName = 'unknown';
                colorIndex = NaN;
            end
        end

        function [colorName, rgb] = deriveColorFromSource(self, sourceFile)
            colorName = 'unknown';
            rgb = [NaN, NaN, NaN];

            if isempty(sourceFile)
                return;
            end

            lowerPath = lower(sourceFile);
            if contains(lowerPath, 'green')
                colorName = 'green';
            elseif contains(lowerPath, 'blue')
                colorName = 'blue';
            elseif contains(lowerPath, 'red')
                colorName = 'red';
            end

            if ~strcmp(colorName, 'unknown')
                rgb = BookManager.namedColorToRgb(colorName);
            end
        end
    end

    methods (Static)
        function colorStr = colorIndexToString(colorIndex)
            switch colorIndex
                case 1
                    colorStr = 'green';
                case 2
                    colorStr = 'blue';
                case 3
                    colorStr = 'red';
                otherwise
                    colorStr = 'unknown';
            end
        end

        function index = colorStringToIndex(colorName)
            if isempty(colorName)
                index = NaN;
                return;
            end

            switch lower(char(colorName))
                case 'green'
                    index = 1;
                case 'blue'
                    index = 2;
                case 'red'
                    index = 3;
                otherwise
                    index = NaN;
            end
        end

        function rgb = namedColorToRgb(colorName)
            switch lower(char(colorName))
                case 'green'
                    rgb = [0, 1, 0];
                case 'blue'
                    rgb = [0, 0, 1];
                case 'red'
                    rgb = [1, 0, 0];
                otherwise
                    rgb = [];
            end
        end

    end
end
