#!/usr/bin/env ruby

require "curses"

Curses.init_screen
Curses.start_color

SCREEN_WIDTH = 80
SCREEN_HEIGHT = 30

FIELD_WIDTH = 12
FIELD_HEIGHT = 18

FIELD = []
(0...FIELD_WIDTH).each do |x|
  (0...FIELD_HEIGHT).each do |y|
    FIELD[y * FIELD_WIDTH + x] = (x == 0 || x == FIELD_WIDTH - 1 || y == FIELD_HEIGHT - 1) ? 9 : 0
  end
end

TETROMINO = Array.new(7) { Array.new }

TETROMINO[0] += "..X.".chars
TETROMINO[0] += "..X.".chars
TETROMINO[0] += "..X.".chars
TETROMINO[0] += "..X.".chars

TETROMINO[1] += "..X.".chars
TETROMINO[1] += ".XX.".chars
TETROMINO[1] += ".X..".chars
TETROMINO[1] += "....".chars

TETROMINO[2] += ".X..".chars
TETROMINO[2] += ".XX.".chars
TETROMINO[2] += "..X.".chars
TETROMINO[2] += "..X.".chars

TETROMINO[3] += "....".chars
TETROMINO[3] += ".XX.".chars
TETROMINO[3] += ".XX.".chars
TETROMINO[3] += "....".chars

TETROMINO[4] += "..X.".chars
TETROMINO[4] += ".XX.".chars
TETROMINO[4] += "..X.".chars
TETROMINO[4] += "....".chars

TETROMINO[5] += "....".chars
TETROMINO[5] += ".XX.".chars
TETROMINO[5] += "..X.".chars
TETROMINO[5] += "..X.".chars

TETROMINO[6] += ".XX.".chars
TETROMINO[6] += ".X..".chars
TETROMINO[6] += ".X..".chars
TETROMINO[6] += ".X..".chars

def rotate(x,y,r)
  case (r % 4)
  when 0
    return y * 4 + x
  when 1
    return 12 + y - (x * 4)
  when 2
    return 15 - (y * 4) - x
  when 3
    return 3 - y + (x * 4)
  else
    return 0
  end
end

def does_piece_fit(id, rotation, posx, posy)
  (0...4).each do |x|
    (0...4).each do |y|
      pi = rotate(x,y,rotation)
      fi = (posy + y) * FIELD_WIDTH + (posx + x)
      if posx + x >= 0 && posx + x < FIELD_WIDTH
        if posy + y >= 0 && posy + y < FIELD_HEIGHT
          return false if (TETROMINO[id][pi] == 'X' && FIELD[fi] != 0)
        end
      end
    end
  end
  return true
end

begin

  win = Curses::Window.new(SCREEN_HEIGHT, SCREEN_WIDTH, 0, 0)
  win.keypad = true
  win.timeout = 5
  win.nodelay = true

  game_over = false

  current_piece = rand(6)
  current_rotation = 0
  current_x = FIELD_WIDTH / 2
  current_y = 0
  speed = 20
  speed_count = 0
  piece_count = 0
  score = 0
  lines = []
  force_down = false

  while (!game_over) do

    # Timing
    sleep(0.05)
    speed_count += 1
    force_down = (speed_count == speed)

    # Input
    key = win.getch

    # Logic
    current_x -= key == Curses::Key::LEFT && does_piece_fit(current_piece, current_rotation, current_x - 1, current_y) ? 1 : 0
    current_x += key == Curses::Key::RIGHT && does_piece_fit(current_piece, current_rotation, current_x + 1, current_y) ? 1 : 0
    current_y += key == Curses::Key::DOWN && does_piece_fit(current_piece, current_rotation, current_x, current_y + 1) ? 1 : 0
    current_rotation += key == Curses::Key::UP && does_piece_fit(current_piece, current_rotation + 1, current_x, current_y) ? 1 : 0

    if force_down
      speed_count = 0
			piece_count += 1
			if (piece_count % 50 == 0) && speed >= 10
        speed -= 1
      end
      if does_piece_fit(current_piece, current_rotation, current_x, current_y + 1)
        current_y += 1
      else
        # Lock Piece
        (0...4).each do |x|
          (0...4).each do |y|
            if TETROMINO[current_piece][rotate(x,y,current_rotation)] != '.'
              FIELD[(current_y + y) * FIELD_WIDTH + (current_x + x)] = current_piece + 1
            end
          end
        end
        # Check for lines
        (0...4).each do |y|
          if (current_y + y < FIELD_HEIGHT - 1)
            line = true
            (1...FIELD_WIDTH - 1).each do |x|
              line = line && ((FIELD[(current_y + y) * FIELD_WIDTH + x]) != 0)
            end
            if line
              (1...FIELD_WIDTH - 1).each do |x|
                FIELD[(current_y + y) * FIELD_WIDTH + x] = 8
              end
              lines << (current_y + y)
            end
          end
        end
        score += 25
        score += (1 << lines.size) * 100 unless lines.empty?
        current_x = FIELD_WIDTH / 2
        current_y = 0
        current_rotation = 0
        current_piece = rand(6)
        game_over = !does_piece_fit(current_piece, current_rotation, current_x, current_y)
      end
    end

    # Render
    screen = Array.new(SCREEN_WIDTH * SCREEN_HEIGHT) { " " }

    # Draw FIELD
    (0...FIELD_WIDTH).each do |x|
      (0...FIELD_HEIGHT).each do |y|
        screen[(y + 2) * SCREEN_WIDTH + (x + 2)] = " ABCDEFG=#".chars[FIELD[y * FIELD_WIDTH + x]]
      end
    end

    # Draw Piece
    (0...4).each do |x|
      (0...4).each do |y|
        if TETROMINO[current_piece][rotate(x,y,current_rotation)] == 'X'
          screen[(current_y + y + 2) * SCREEN_WIDTH + (current_x + x + 2)] = (current_piece + 65).chr
        end
      end
    end

    score_string = ("SCORE: %8d" % score).chars
    score_start = 2 * SCREEN_WIDTH + FIELD_WIDTH + 6
    score_end = score_start + score_string.size
    screen[score_start...score_end] = score_string

    # Remove Lines
    if !lines.empty?
      lines.each do |l|
        (1...FIELD_WIDTH - 1).each do |x|
          (l).downto(0) do |y|
            FIELD[y * FIELD_WIDTH + x] = FIELD[(y - 1) * FIELD_WIDTH + x]
          end
          FIELD[x] = 0
        end
      end
			lines.clear
    end

    # Update Screen
    win.clear
    win.addstr(screen.join)
    win.refresh

  end

  puts "Game Over!! Score: %8d" % score
  sleep(10)

ensure
  Curses.close_screen
end
