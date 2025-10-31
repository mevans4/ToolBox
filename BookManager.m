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
    end

    methods
        function self = BookManager()
            self.originalBookHandles = {};
            self.currentBookIndex = 1;
            self.booksPlaced = 0;

            defaultStackHeight = self.bookHeights - 0.05;
            self.colorStackBases = struct(
                'green', [0.45, -0.525, defaultStackHeight], ...
                'blue',  [0.15, -0.525, defaultStackHeight], ...
                'red',   [-0.15, -0.525, defaultStackHeight]);
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

                    colorInfo = self.captureColorInformation(obj);

                    actualBooks{end+1} = struct(...
                        'handle', obj, ...
                        'position', objPos, ...
                        'originalVerts', verts, ...
                        'topSurfacePosition', topSurfacePos, ...
                        'faceColor', colorInfo.faceColor, ...
                        'colorName', colorInfo.colorName, ...
                        'sourceFile', colorInfo.sourceFile);
                end
            end

            fprintf('Found %d books\n', length(actualBooks));
            self.matchBooksToPositions(actualBooks);

            fprintf('Book order:\n');
            for i = 1:length(self.originalBookHandles)
                bookInfo = self.originalBookHandles{i};
                fprintf('  %d. %s book at [%.3f, %.3f, %.3f]\n', ...
                    i, self.getBookColorString(bookInfo), ...
                    bookInfo.position(1), bookInfo.position(2), bookInfo.position(3));
            end
        end

        function matchBooksToPositions(self, actualBooks)
            self.originalBookHandles = {};

            totalBooks = length(actualBooks);
            if totalBooks ~= 6
                fprintf('Warning: Expected 6 books, found %d\n', totalBooks);
            end

            for i = 1:totalBooks
                actualBook = actualBooks{i};
                [colorName, colorIndex, colorRGB] = self.determineBookColor(actualBook);

                bookHeight = self.estimateBookHeight(actualBook);

                bookInfo = struct(...
                    'handle', actualBook.handle, ...
                    'originalVerts', actualBook.originalVerts, ...
                    'position', actualBook.position, ...
                    'topSurfacePosition', actualBook.topSurfacePosition, ...
                    'color', colorName, ...
                    'colorRGB', colorRGB, ...
                    'height', bookHeight);

                if ~isnan(colorIndex)
                    bookInfo.colorIndex = colorIndex;
                end

                self.originalBookHandles{end+1} = bookInfo;
            end
        end

        function colorStr = colorIndexToString(~, colorIndex)
            switch colorIndex
                case 1, colorStr = 'green';
                case 2, colorStr = 'blue';
                case 3, colorStr = 'red';
                otherwise, colorStr = 'unknown';
            end
        end

        function [bookPos, bookColor, bookIndex, bookHandle, originalVerts, topSurfacePos] = getNextBook(self)
            if isempty(self.originalBookHandles) || self.currentBookIndex > length(self.originalBookHandles)
                bookPos = []; bookColor = ''; bookIndex = 0;
                bookHandle = []; originalVerts = []; topSurfacePos = [];
                return;
            end

            bookInfo = self.originalBookHandles{self.currentBookIndex};
            bookPos = bookInfo.position;
            bookHandle = bookInfo.handle;
            originalVerts = bookInfo.originalVerts;
            topSurfacePos = bookInfo.topSurfacePosition;
            bookIndex = self.currentBookIndex;
            bookColor = self.getBookColorString(bookInfo);

            fprintf('Next book: %s at [%.3f, %.3f, %.3f] (%d/%d)\n', ...
                bookColor, bookPos(1), bookPos(2), bookPos(3), ...
                self.currentBookIndex, length(self.originalBookHandles));
        end

        function removeBook(self, bookColor, bookIndex)
            if bookIndex <= length(self.originalBookHandles)
                fprintf('Removed %s book %d\n', bookColor, bookIndex);
                self.currentBookIndex = self.currentBookIndex + 1;
            end
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
                otherwise
                    targetPos = [];
            end
        end

        function finalPos = getMotomanFinalPosition(self, bookIndex)
            if bookIndex == 4
                finalPos = [0, 1.05, 0.079];
            else
                finalPos = [0, 1.05, 0.079*2];
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

        function [colorName, colorIndex, colorRGB] = determineBookColor(self, actualBook)
            [colorRGB, explicitName] = self.extractColorData(actualBook);

            if ~isempty(explicitName)
                colorName = lower(char(explicitName));
                colorIndex = self.colorStringToIndex(colorName);
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

        function [rgb, explicitName] = extractColorData(self, actualBook)
            rgb = [NaN, NaN, NaN];
            explicitName = '';

            if isfield(actualBook, 'colorName') && ~isempty(actualBook.colorName)
                explicitName = lower(char(actualBook.colorName));
                namedRgb = self.namedColorToRgb(explicitName);
                if ~isempty(namedRgb)
                    rgb = namedRgb;
                    return;
                end
            end

            if isfield(actualBook, 'faceColor') && ~isempty(actualBook.faceColor)
                [rgb, explicitName] = self.parseColorValue(actualBook.faceColor);
            end

            if all(isnan(rgb)) && isfield(actualBook, 'handle') && ~isempty(actualBook.handle) && isgraphics(actualBook.handle)
                faceColor = get(actualBook.handle, 'FaceColor');
                [rgb, explicitName] = self.parseColorValue(faceColor);
            end

            if all(isnan(rgb)) && isfield(actualBook, 'handle') && ~isempty(actualBook.handle) && isgraphics(actualBook.handle)
                try
                    faceVertexCData = get(actualBook.handle, 'FaceVertexCData');
                    if isnumeric(faceVertexCData)
                        rgb = self.averageColorArray(faceVertexCData);
                    end
                catch
                end
            end

            if all(isnan(rgb)) && isfield(actualBook, 'sourceFile') && ~isempty(actualBook.sourceFile)
                [explicitName, rgb] = self.deriveColorFromSource(actualBook.sourceFile);
            end
        end

        function [colorName, colorIndex] = mapRgbToKnownColor(self, rgb)
            if isempty(rgb) || any(isnan(rgb))
                colorName = 'unknown';
                colorIndex = NaN;
                return;
            end

            rgb = double(rgb(:)');
            maxValue = max(rgb);
            if maxValue > 1
                rgb = rgb / maxValue;
            end

            knownColors = struct(...
                'green', [0, 1, 0], ...
                'blue',  [0, 0, 1], ...
                'red',   [1, 0, 0]);

            names = fieldnames(knownColors);
            diffs = zeros(length(names), 1);
            for idx = 1:length(names)
                ref = knownColors.(names{idx});
                diffs(idx) = norm(rgb - ref);
            end

            [minDiff, minIdx] = min(diffs);
            tolerance = 0.35;
            if minDiff <= tolerance
                colorName = names{minIdx};
                colorIndex = self.colorStringToIndex(colorName);
            else
                colorName = 'unknown';
                colorIndex = NaN;
            end
        end

        function colorInfo = captureColorInformation(self, handle)
            colorInfo = struct('faceColor', [], 'colorName', '', 'sourceFile', '');

            if isempty(handle) || ~isgraphics(handle)
                return;
            end

            faceColor = get(handle, 'FaceColor');
            if ~isempty(faceColor)
                [parsedRgb, explicitName] = self.parseColorValue(faceColor);
                if ~all(isnan(parsedRgb))
                    colorInfo.faceColor = parsedRgb;
                end
                if ~isempty(explicitName)
                    colorInfo.colorName = explicitName;
                end
            end

            userData = get(handle, 'UserData');
            if ischar(userData) || (isstring(userData) && isscalar(userData))
                colorInfo.sourceFile = char(userData);
            elseif isstruct(userData) && isfield(userData, 'sourceFile')
                colorInfo.sourceFile = userData.sourceFile;
                if isfield(userData, 'colorName')
                    colorInfo.colorName = userData.colorName;
                end
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
                rgb = self.namedColorToRgb(colorName);
            end
        end

        function [rgb, explicitName] = parseColorValue(self, value)
            explicitName = '';
            rgb = [NaN, NaN, NaN];

            if isnumeric(value) && numel(value) == 3
                rgb = double(value(:)');
            elseif ischar(value) || (isstring(value) && isscalar(value))
                candidate = lower(char(value));
                namedRgb = self.namedColorToRgb(candidate);
                if ~isempty(namedRgb)
                    explicitName = candidate;
                    rgb = namedRgb;
                end
            end
        end

        function rgb = namedColorToRgb(~, colorName)
            switch lower(char(colorName))
                case 'green', rgb = [0, 1, 0];
                case 'blue',  rgb = [0, 0, 1];
                case 'red',   rgb = [1, 0, 0];
                otherwise,    rgb = [];
            end
        end

        function rgb = averageColorArray(~, colorArray)
            if isempty(colorArray) || size(colorArray, 2) < 3
                rgb = [NaN, NaN, NaN];
                return;
            end

            rgb = mean(double(colorArray(:, 1:3)), 1);
            maxVal = max(rgb);
            if maxVal > 1
                rgb = rgb / maxVal;
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
    end
end
