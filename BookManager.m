classdef BookManager < handle
    %BOOKMANAGER Tracks book instances and manages colour-specific stacks.

    properties
        originalBookHandles cell = {};
        bookHeights double = 0.079;
        currentBookIndex double = 1;
        booksPlaced double = 0;

        hardcodedBooks cell = {
            [-1.75,  0.2, 0.079*2, 3];
            [-1.75, -0.2, 0.079*2, 3];
            [-1.75,  0.2, 0.079*1, 2];
            [-1.75, -0.2, 0.079*1, 2];
            [-1.75,  0.2, 0.079*0, 1];
            [-1.75, -0.2, 0.079*0, 1]
            };

        colorStackBases struct;
        colorStackCounts struct;
        colorStackRecords struct;

        robotDeliveryBases struct;
        robotDeliveryCounts struct;
        deliveryLog cell = {};
    end

    methods
        function self = BookManager()
            defaultStackHeight = self.bookHeights - 0.05;

            self.colorStackBases = struct();
            self.colorStackBases.green = [0.45, -0.525, defaultStackHeight];
            self.colorStackBases.blue = [0.15, -0.525, defaultStackHeight];
            self.colorStackBases.red = [-0.15, -0.525, defaultStackHeight];

            emptyRecord = struct('handle', {}, 'color', {}, 'position', {}, ...
                                 'topSurface', {}, 'originalVerts', {}, 'height', {}, ...
                                 'isProcessed', {});
            self.colorStackRecords = struct();
            self.colorStackRecords.green = emptyRecord;
            self.colorStackRecords.blue = emptyRecord;
            self.colorStackRecords.red = emptyRecord;

            self.robotDeliveryBases = struct();
            self.robotDeliveryBases.Motoman = [0.85, 1.05, defaultStackHeight];
            self.robotDeliveryBases.Kuka = [-0.85, -1.05, defaultStackHeight];
            self.robotDeliveryBases.Aubo = [1.35, -0.25, defaultStackHeight];
            self.robotDeliveryCounts = struct('Motoman', 0, 'Kuka', 0, 'Aubo', 0);

            self.resetColorStacks();
        end

        function storeBookHandles(self)
            %STOREBOOKHANDLES Discover all book meshes in the workspace and cache their data.
            fprintf('Setting up book positions...\n');

            allObjs = findobj('Type', 'patch');
            bookRecords = [];

            for idx = 1:numel(allObjs)
                obj = allObjs(idx);
                verts = get(obj, 'Vertices');
                if isempty(verts)
                    continue;
                end

                try
                    record = self.buildBookRecord(obj, verts);
                catch
                    continue;
                end

                if strlength(record.color) == 0
                    continue;
                end

                bookRecords(end+1) = record; %#ok<AGROW>
            end

            if isempty(bookRecords)
                warning('BookManager:NoBooksFound', 'No book patches detected in the workspace.');
                self.originalBookHandles = {};
                return;
            end

            heights = arrayfun(@(r) r.topSurface(3), bookRecords);
            [~, order] = sort(heights, 'descend');
            bookRecords = bookRecords(order);

            self.originalBookHandles = arrayfun(@(r) r, bookRecords, 'UniformOutput', false);
            self.currentBookIndex = 1;
            self.booksPlaced = 0;

            fprintf('Detected %d books for processing.\n', numel(self.originalBookHandles));
            for i = 1:numel(self.originalBookHandles)
                rec = self.originalBookHandles{i};
                fprintf('  Book %d: %s at [%.3f, %.3f, %.3f] (top %.3f)\n', ...
                    i, rec.color, rec.position(1), rec.position(2), rec.position(3), rec.topSurface(3));
            end
        end

        function [bookPos, bookColor, bookIndex, bookHandle, originalVerts, topSurfacePos] = getNextBook(self)
            %GETNEXTBOOK Fetch the next unprocessed book from the detected list.
            bookPos = [];
            bookColor = '';
            bookIndex = NaN;
            bookHandle = [];
            originalVerts = [];
            topSurfacePos = [];

            totalBooks = numel(self.originalBookHandles);
            while self.currentBookIndex <= totalBooks
                record = self.originalBookHandles{self.currentBookIndex};
                if isfield(record, 'isProcessed') && record.isProcessed
                    self.currentBookIndex = self.currentBookIndex + 1;
                    continue;
                end

                handle = record.handle;
                if isempty(handle) || ~isgraphics(handle)
                    self.currentBookIndex = self.currentBookIndex + 1;
                    continue;
                end

                verts = get(handle, 'Vertices');
                if isempty(verts)
                    self.currentBookIndex = self.currentBookIndex + 1;
                    continue;
                end

                center = mean(verts, 1);
                topSurface = [center(1), center(2), max(verts(:, 3))];

                record.position = center;
                record.topSurface = topSurface;
                self.originalBookHandles{self.currentBookIndex} = record;

                bookPos = center;
                bookColor = char(record.color);
                bookIndex = self.currentBookIndex;
                bookHandle = handle;
                originalVerts = record.originalVerts;
                topSurfacePos = topSurface;

                fprintf('Next book %d selected (%s) at [%.3f, %.3f, %.3f].\n', ...
                    bookIndex, record.color, center(1), center(2), center(3));

                self.currentBookIndex = self.currentBookIndex + 1;
                return;
            end

            self.currentBookIndex = totalBooks + 1;
            fprintf('No more books available for initial sorting.\n');
        end

        function removeBook(self, colorName, bookIndex)
            if nargin < 3
                bookIndex = NaN;
            end

            if ~isnan(bookIndex) && bookIndex >= 1 && bookIndex <= numel(self.originalBookHandles)
                record = self.originalBookHandles{bookIndex};
            else
                record = [];
            end

            if isempty(record)
                % Attempt to locate by colour
                targetColor = lower(char(colorName));
                for idx = 1:numel(self.originalBookHandles)
                    rec = self.originalBookHandles{idx};
                    if rec.isProcessed
                        continue;
                    end
                    if strcmpi(rec.color, targetColor)
                        record = rec;
                        bookIndex = idx;
                        break;
                    end
                end
            end

            if isempty(record)
                return;
            end

            record.isProcessed = true;
            self.originalBookHandles{bookIndex} = record;
            self.booksPlaced = self.booksPlaced + 1;
        end

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
                otherwise
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
                if ~isempty(book.handle) && isgraphics(book.handle)
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

        function targetPos = getMotomanTargetPosition(~, bookIndex)
            switch bookIndex
                case 3
                    targetPos = [-0.5, 0.525, 0 + 0.005];
                case 4
                    targetPos = [-0.5, 0.525, 0.079 + 0.005];
                otherwise
                    targetPos = [-0.5, 0.525, 0.079 + 0.005];
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
            emptyRecord = struct('handle', {}, 'color', {}, 'position', {}, 'topSurface', {}, 'originalVerts', {}, 'height', {}, 'isProcessed', {});
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
            entry.isProcessed = true;

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

            logEntry = struct();
            logEntry.robot = char(robotKey);
            logEntry.color = char(colorName);
            logEntry.position = finalCenter;
            logEntry.timestamp = datetime('now');

            if nargin >= 5
                logEntry.handle = bookHandle;
            else
                logEntry.handle = [];
            end

            self.deliveryLog{end+1} = logEntry;

            robotField = matlab.lang.makeValidName(robotKey);
            if isfield(self.robotDeliveryCounts, robotField)
                self.robotDeliveryCounts.(robotField) = self.robotDeliveryCounts.(robotField) + 1;
            end
        end

        function colorStr = getBookColorString(self, bookInfo)
            if isstruct(bookInfo) && isfield(bookInfo, 'color') && ~isempty(bookInfo.color)
                colorStr = char(bookInfo.color);
            elseif isstruct(bookInfo) && isfield(bookInfo, 'colorIndex')
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

        function name = colorIndexToString(~, index)
            switch index
                case 1, name = 'green';
                case 2, name = 'blue';
                case 3, name = 'red';
                otherwise, name = 'unknown';
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

    methods (Access = private)
        function record = buildBookRecord(self, handle, verts)
            center = mean(verts, 1);
            maxVals = max(verts, [], 1);
            minVals = min(verts, [], 1);

            record = struct();
            record.handle = handle;
            record.position = center;
            record.originalVerts = verts;
            record.topSurface = [center(1), center(2), maxVals(3)];
            record.bottomSurface = [center(1), center(2), minVals(3)];
            record.height = maxVals(3) - minVals(3);
            record.isProcessed = false;
            record.source = '';

            userData = get(handle, 'UserData');
            if isstruct(userData) && isfield(userData, 'sourceFile')
                record.source = char(userData.sourceFile);
            end

            colorName = "";
            if isstruct(userData)
                if isfield(userData, 'colorName') && ~isempty(userData.colorName)
                    colorName = string(lower(char(userData.colorName)));
                elseif isfield(userData, 'sourceFile')
                    colorName = string(self.colorNameFromToken(userData.sourceFile));
                end
            end

            if strlength(colorName) == 0
                colorName = string(self.colorNameFromToken(record.source));
            end

            if strlength(colorName) == 0
                colorName = string(self.colorNameFromRGB(handle));
            end

            record.color = char(colorName);
            record.colorIndex = self.colorStringToIndex(colorName);
        end

        function colorName = colorNameFromToken(~, token)
            colorName = '';
            if isempty(token)
                return;
            end
            token = lower(char(token));
            if contains(token, 'green')
                colorName = 'green';
            elseif contains(token, 'blue')
                colorName = 'blue';
            elseif contains(token, 'red')
                colorName = 'red';
            end
        end

        function colorName = colorNameFromRGB(~, handle)
            colorName = '';
            try
                faceColor = get(handle, 'FaceColor');
                if isnumeric(faceColor) && numel(faceColor) == 3
                    rgb = double(faceColor(:)');
                else
                    colorArray = get(handle, 'FaceVertexCData');
                    if isempty(colorArray)
                        rgb = [];
                    else
                        rgb = mean(double(colorArray(:, 1:3)), 1);
                    end
                end

                if isempty(rgb)
                    return;
                end

                rgb = rgb / max(1, max(rgb));
                [~, idx] = max(rgb);
                switch idx
                    case 1, colorName = 'red';
                    case 2, colorName = 'green';
                    case 3, colorName = 'blue';
                end
            catch
                colorName = '';
            end
        end
    end
end