classdef BookSpawner
    methods (Static)
        function spawnBooks()
            % BOOK PLACEMENT - Green Books
            book_data_green = [
                -1.75, 0.2, 0.079*0, 0, 1, 0;   % Book 1
                -1.75, -0.2, 0.079*0, 0, 1, 0;   % Book 4
                ];

            for i = 1:size(book_data_green, 1)
                posG = book_data_green(i, 1:3);
                colourG = book_data_green(i, 4:6);
                book_handle_G = PlaceObject('Environment\greenBook.ply', posG);
                set(book_handle_G, 'FaceColor', colourG);
                set(book_handle_G,'EdgeColor',  'none');
            end

            % BOOK PLACEMENT - Blue Books
            book_data_blue = [
                -1.75, 0.2, 0.079*1, 0,0,1;   % Book 2
                -1.75, -0.2, 0.079*1, 0,0,1;   % Book 5
                ];

            for i = 1:size(book_data_blue, 1)
                posB = book_data_blue(i, 1:3);
                colourB = book_data_blue(i, 4:6);
                book_handle_B = PlaceObject('Environment\blueBook.ply', posB);
                set(book_handle_B, 'FaceColor', colourB);
                set(book_handle_B,'EdgeColor', 'none');
            end

            % BOOK PLACEMENT - Red Books
            book_data_red = [
                -1.75, 0.2, 0.079*2,1,0,0;   % Book 3
                -1.75, -0.2, 0.079*2,1,0,0;   % Book 6
                ];

            for i = 1:size(book_data_red, 1)
                posR = book_data_red(i, 1:3);
                colourR = book_data_red(i, 4:6);
                book_handle_R = PlaceObject('Environment\redBook.ply', posR);
                set(book_handle_R, 'FaceColor', colourR);
                set(book_handle_R,'EdgeColor', 'none');
            end
        end
        
        function drawBookStartMarkers()

            book_starter_size = 0.3;
            books1_pos_x = -1.75;
            books1_pos_y = 0.2;

            rectangle('Position', [books1_pos_x-book_starter_size/2, books1_pos_y-book_starter_size/2, book_starter_size, book_starter_size], ...
                'FaceColor', 'white', 'EdgeColor', 'black', 'LineWidth', 2);
            rectangle('Position', [books1_pos_x-book_starter_size/2, -books1_pos_y-book_starter_size/2, book_starter_size, book_starter_size], ...
                'FaceColor', 'white', 'EdgeColor', 'black', 'LineWidth', 2);
        end
    end
end