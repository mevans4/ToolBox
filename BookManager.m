classdef BookManager < handle
    properties
        originalBookHandles = {};
        bookHeights = 0.079;
        currentBookIndex = 1;
        booksPlaced = 0;

        hardcodedBooks = {
            [-1.75,  0.2, 0.079*2, 3];
            [-1.75, -0.2, 0.079*2, 3];
            [-1.75,  0.2, 0.079*1, 2];
            [-1.75, -0.2, 0.079*1, 2];
            [-1.75,  0.2, 0.079*0, 1];
            [-1.75, -0.2, 0.079*0, 1]
            };

        colorStackBases = struct();
        colorStackCounts = struct();
        colorStackRecords = struct();

        robotDeliveryBases = struct();
        robotDeliveryCounts = struct();
        deliveryLog = {};
    end

    methods
        function self = BookManager()
            self.originalBookHandles = {};
            self.currentBookIndex = 1;
            self.booksPlaced = 0;

            defaultStackHeight = self.bookHeights - 0.05;

            
            self.colorStackBases = struct();
            self.colorStackBases.green = [0.45, -0.525, defaultStackHeight];
            self.colorStackBases.blue = [0.15, -0.525, defaultStackHeight];
            self.colorStackBases.red = [-0.15, -0.525, defaultStackHeight];

            emptyRecord = struct('handle', {}, 'color', {}, 'position', {}, ...
                                 'topSurface', {}, 'originalVerts', {}, 'height', {});
            self.colorStackRecords = struct();
            self.colorStackRecords.green = emptyRecord;
            self.colorStackRecords.blue = emptyRecord;
            self.colorStackRecords.red = emptyRecord;

            self.robotDeliveryBases = struct();
            self.robotDeliveryBases.Motoman = [0.85, 1.05, defaultStackHeight];
            self.robotDeliveryBases.Kuka = [-0.85, -1.05, defaultStackHeight];
            self.robotDeliveryBases.Aubo = [1.35, -0.25, defaultStackHeight];
            self.robotDeliveryCounts = struct('Motoman', 0, 'Kuka', 0, 'Aubo', 0);
            self.deliveryLog = {};

            self.resetColorStacks();
        end

        function storeBookHandles(self)
            fprintf('Setting up book positions...\n');

            allObjs = findobj('Type', 'patch');
            actualBooks = {};

            for i = 1:length(allObjs)
                obj = allObjs(i);
                verts = get(obj, 'Vertices');

                if isempty(verts)
                    continue;
                end

                objPos = mean(verts, 1);
                isInBookArea = abs(objPos(1) - (-1.75)) < 0.3;

                if isInBookArea
                    minVerts = min(verts);
                    maxVerts = max(verts);
                    topSurfacePos = [objPos(1), objPos(2), maxVerts(3)];


        function targetPos = getTargetPosition(self, ~)
            switch self.booksPlaced
                case 0
                    targetPos = [-0.5, -0.25*2.1, 0.079 - 0.05];
                case 1
                    targetPos = [-0.5, -0.25*2.1, 0.079*2 - 0.05];
                case 2
                    targetPos = [-0.5, 0.25*2.1, 0.079 - 0.05];
                case 3
                    targetPos = [-0.5, 0.25*2.1, 0.079*2 - 0.05];
                case 4
                    targetPos = [0, 0, 0.079 - 0.05];
                case 5
                    targetPos = [0, 0, 0.079*2 - 0.05];
            end

            self.booksPlaced = self.booksPlaced + 1;
            fprintf('Stack position: [%.3f, %.3f, %.3f]\n', targetPos(1), targetPos(2), targetPos(3));
        end

        function reset(self)
            self.currentBookIndex = 1;
            self.booksPlaced = 0;
            self.originalBookHandles = {};
            self.resetColorStacks();
            self.robotDeliveryCounts = struct('Motoman', 0, 'Kuka', 0, 'Aubo', 0);
            self.deliveryLog = {};
            fprintf('Book manager reset\n');
        end

        function verifyBookPositions(self)
            fprintf('Checking book positions...\n');
            for i = 1:length(self.originalBookHandles)
                book = self.originalBookHandles{i};
                if ~isempty(book.handle) && isvalid(book.handle)
                    currentVerts = get(book.handle, 'Vertices');
                    currentPos = mean(currentVerts, 1);
                    fprintf('Book %d (%s):\n', i, self.getBookColorString(book));
                    fprintf('  Expected: [%.3f, %.3f, %.3f]\n', book.position(1), book.position(2), book.position(3));
                    fprintf('  Actual:   [%.3f, %.3f, %.3f]\n', currentPos(1), currentPos(2), currentPos(3));
                else
                    fprintf('Book %d: missing\n', i);
                end
            end
        end
% Motoman books
        function targetPos = getMotomanTargetPosition(self, bookIndex)
            switch bookIndex
                case 3
                    targetPos = [-0.5, 0.525, 0+0.005];
                case 4
                    targetPos = [-0.5, 0.525, 0.079+0.005];
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
            basePos = self.colorStackBases.(colorName);
            targetPos = [basePos(1), basePos(2), basePos(3) + level * self.bookHeights];
            self.colorStackCounts.(colorName) = level + 1;

            fprintf('Assigned %s stack position: [%.3f, %.3f, %.3f] (level %d)\n', ...
                colorName, targetPos(1), targetPos(2), targetPos(3), level + 1);
        end

        function resetColorStacks(self)
            self.colorStackCounts = struct('green', 0, 'blue', 0, 'red', 0);
            emptyRecord = struct('handle', {}, 'color', {}, 'position', {}, 'topSurface', {}, 'originalVerts', {}, 'height', {});
            self.colorStackRecords.green = emptyRecord;
            self.colorStackRecords.blue = emptyRecord;
            self.colorStackRecords.red = emptyRecord;
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
            records = self.colorStackRecords.(colorName);
            count = numel(records);
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

            basePos = self.robotDeliveryBases.(robotField);
            level = self.robotDeliveryCounts.(robotField);
            targetPos = [basePos(1), basePos(2), basePos(3) + level * self.bookHeights];
        end

        function registerDeliveryPlacement(self, robotKey, colorName, finalCenter, bookHandle)
            if nargin < 4
                finalCenter = [NaN, NaN, NaN];
            end

            logEntry = struct(
                'robot', char(robotKey), ...
                'color', char(colorName), ...
                'position', finalCenter, ...
                'timestamp', datetime('now'), ...
                'handle', []);

            if nargin >= 5
                logEntry.handle = bookHandle;
            end

            self.deliveryLog{end+1} = logEntry;

            robotField = matlab.lang.makeValidName(robotKey);
            if isfield(self.robotDeliveryCounts, robotField)
                self.robotDeliveryCounts.(robotField) = self.robotDeliveryCounts.(robotField) + 1;
            end
        end

        function colorStr = getBookColorString(self, bookInfo)
            if isfield(bookInfo, 'color') && ~isempty(bookInfo.color)
                colorStr = char(bookInfo.color);
            elseif isfield(bookInfo, 'colorIndex')
                colorStr = self.colorIndexToString(bookInfo.colorIndex);
            else
                colorStr = 'unknown';
            end
        end

        function colorIndex = colorStringToIndex(~, colorName)
            if isempty(colorName)
                colorIndex = NaN;
                return;
            end

            switch lower(char(colorName))
                case 'green', colorIndex = 1;
                case 'blue',  colorIndex = 2;
                case 'red',   colorIndex = 3;
                otherwise,    colorIndex = NaN;
            end
        end

            end

            rgb = mean(double(colorArray(:, 1:3)), 1);
            maxVal = max(rgb);
            if maxVal > 1
                rgb = rgb/maxVal;
            end
        end

        function height = estimateBookHeight(~, actualBook)
            height = NaN;
            if isfield(actualBook, 'originalVerts') && ~isempty(actualBook.originalVerts)
                try
                    minZ = min(actualBook.originalVerts(:, 3));
                    maxZ = max(actualBook.originalVerts(:, 3));
                    height = maxZ - minZ;
                catch
                    height = NaN;
                end
            end

            if isnan(height) && isfield(actualBook, 'topSurfacePosition') && ~isempty(actualBook.topSurfacePosition)
                height = actualBook.topSurfacePosition(3);
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
    end
end
