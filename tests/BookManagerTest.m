classdef BookManagerTest < matlab.unittest.TestCase
    methods (Test)
        function matchBooksPreservesPositions(testCase)
            manager = BookManager();

            book1 = BookManagerTest.createBookStruct([0.12, -0.34, 0.05], 0.08, [0, 1, 0]);
            book2 = BookManagerTest.createBookStruct([-0.42, 0.18, 0.04], 0.08, [1, 0, 0]);

            manager.matchBooksToPositions({book1, book2});

            testCase.verifyEqual(numel(manager.originalBookHandles), 2);

            stored1 = manager.originalBookHandles{1};
            stored2 = manager.originalBookHandles{2};

            testCase.verifyEqual(stored1.position, book1.position, 'AbsTol', 1e-10);
            testCase.verifyEqual(stored1.topSurfacePosition, book1.topSurfacePosition, 'AbsTol', 1e-10);
            testCase.verifyEqual(stored2.position, book2.position, 'AbsTol', 1e-10);
            testCase.verifyEqual(stored2.topSurfacePosition, book2.topSurfacePosition, 'AbsTol', 1e-10);
        end

        function matchBooksCapturesColorInformation(testCase)
            manager = BookManager();

            bookGreen = BookManagerTest.createBookStruct([0, 0, 0.03], 0.07, [0, 1, 0]);
            bookBlue = BookManagerTest.createBookStruct([0.2, 0.1, 0.03], 0.07, [0, 0, 1]);
            bookUnknown = BookManagerTest.createBookStruct([-0.15, 0.05, 0.03], 0.07, [0.5, 0.5, 0.5]);

            manager.matchBooksToPositions({bookGreen, bookBlue, bookUnknown});

            stored = manager.originalBookHandles;

            testCase.verifyEqual(stored{1}.color, 'green');
            testCase.verifyEqual(stored{1}.colorIndex, 1);
            testCase.verifyEqual(stored{1}.colorRGB, [0, 1, 0], 'AbsTol', 1e-10);

            testCase.verifyEqual(stored{2}.color, 'blue');
            testCase.verifyEqual(stored{2}.colorIndex, 2);
            testCase.verifyEqual(stored{2}.colorRGB, [0, 0, 1], 'AbsTol', 1e-10);

            testCase.verifyEqual(stored{3}.color, 'unknown');
            testCase.verifyTrue(~isfield(stored{3}, 'colorIndex') || isnan(stored{3}.colorIndex));
            testCase.verifyEqual(stored{3}.colorRGB, [0.5, 0.5, 0.5], 'AbsTol', 1e-10);
        end
    end

    methods (Static)
        function book = createBookStruct(position, height, faceColor)
            halfSize = [0.02, 0.015, height / 2];
            verts = [
                position(1) - halfSize(1), position(2) - halfSize(2), position(3) - halfSize(3);
                position(1) + halfSize(1), position(2) - halfSize(2), position(3) - halfSize(3);
                position(1) - halfSize(1), position(2) + halfSize(2), position(3) - halfSize(3);
                position(1) + halfSize(1), position(2) + halfSize(2), position(3) - halfSize(3);
                position(1) - halfSize(1), position(2) - halfSize(2), position(3) + halfSize(3);
                position(1) + halfSize(1), position(2) - halfSize(2), position(3) + halfSize(3);
                position(1) - halfSize(1), position(2) + halfSize(2), position(3) + halfSize(3);
                position(1) + halfSize(1), position(2) + halfSize(2), position(3) + halfSize(3)
            ];

            book = struct( ...
                'handle', [], ...
                'position', position, ...
                'originalVerts', verts, ...
                'topSurfacePosition', [position(1), position(2), position(3) + halfSize(3)], ...
                'faceColor', faceColor, ...
                'colorName', '', ...
                'sourceFile', '' ...
            );
        end
    end
end
