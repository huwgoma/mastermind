# frozen_string_literal: true
require 'colorize'
require 'pry'
# Module - Namespace for the game rules
module Rules
  def instructions
    how_to_play
    how_to_play_clues
    how_to_play_start
  end

  def how_to_play
    puts "\n#{'How to play Mastermind'.bold}\n\n"
    puts 'This is a 1-player game played against the computer.'
    puts "You can choose to either be the #{'Code Maker'.bold} or the #{'Code Breaker'.bold}."
    puts 'There are 6 different number options:'
    display_number_options
    puts 'The Code Maker will choose 4 random numbers to create a code. For example:'
    display_code_example(1, 3, 4, 1)
    puts "\n\nThe Code Breaker will try to guess the code within 12 turns."
  end

  def how_to_play_clues
    puts "\n#{'Clues'.bold}\n\n"
    puts 'After every guess, the Code Maker will provide you with up to 4 clues.'
    display_clue_options
    puts "\n#{'Clue Example'.bold}\n\n"
    puts "For example: Guessing '1463' will produce 3 clues: "
    display_code_example(1, 4, 6, 3)
    display_clue_example([1, 4, 6, 3], [1, 3, 4, 1])
  end
  
  def how_to_play_start
    puts "Time to play!\n"
  end
  
  private

  def display_number_options
    puts "\n"
    Board::NUMBER_OPTIONS_DISPLAY.each { |_number, number_display| print "#{number_display} " }
    puts "\n\n"
  end
  
  def display_code_example(number_one, number_two, number_three, number_four)
    puts "\n"
    [number_one, number_two, number_three, number_four].each do |number|
      print "#{Board::NUMBER_OPTIONS_DISPLAY[number]} "
    end
  end

  def display_clue_options
    puts "\n"
    print "#{Board::CLUE_OPTIONS_DISPLAY[:correct_number_correct_position]} "
    puts "A #{'red dot'.colorize(:red)} indicates that your guess contains 1 correct number in the correct position."
    print "#{Board::CLUE_OPTIONS_DISPLAY[:correct_number_wrong_position]} "
    puts "An empty dot indicates that your guess contains 1 correct number, but in the wrong position.\n"
  end

  def display_clue_example(guess, code)
    clues = Clue.new(guess, code).return_clues
    clues_display(clues)
  end
end

# Module - Namespace for the in-game text
module GameText
  def choose_role_prompt
    'Would you like to play as the Code Maker (1) or the Code Breaker (2)?'
  end

  def invalid_role_number_warning
    'Enter 1 to play as the Code Maker, or 2 to play as the Code Breaker:'.colorize(:red).bold
  end

  def user_code_prompt
    'Please enter your 4-digit code: '
  end

  def invalid_user_code_warning
    'Your code must be 4-digit number using numbers between 1-6:'.colorize(:red).bold
  end

  def computer_code_created
    'The computer has chosen its 4-digit code.'
  end

  def user_guess_prompt
    'Please enter your guess: '
  end

  def invalid_guess_warning
    'Your guess should be a 4-digit number (each digit should be between 1-6): '.colorize(:red).bold
  end
  
  def display_turn
    puts turn_number_display
    guess_display
    print clue_text
    clues_display(clues)
  end

  def turn_number_display
    "\nTurn: #{board.turn_number}\n\n"
  end

  def guess_display
    guess.each { |number| print "#{Board::NUMBER_OPTIONS_DISPLAY[number]} " }
  end

  def clues_display(clues)
    clues.each { |clue| print "#{clue} " }
    puts "\n\n"
  end
  
  def clue_text
    'Clues for this guess: '
  end

  def user_code_breaker_win
    "Victory! You broke the computer's code!"
  end

  def user_code_breaker_loss
    "Game over. You couldn't break the computer's code."
  end

  def reveal_code
    puts "This is the code you were trying to crack: \n"
    code.each { |number| print "#{Board::NUMBER_OPTIONS_DISPLAY[number]} " }
    puts "\n\n"
  end

  def computer_code_breaker_win
    'Game over. The computer broke your code.'
  end

  def computer_code_breaker_loss
    'Congratulations, you broke the computer. No but actually how did you get here?'
  end

  def prompt_replay
    'Play again? Press Y for Yes, or anything else for no.'
  end
end

# Class - The Mastermind game 'Board'
class Board
  attr_accessor :turn_number

  def initialize
    @turn_number = 1
  end

  def increment_turn
    self.turn_number += 1
  end

  NUMBER_OPTIONS = Array(1..6)

  NUMBER_OPTIONS_DISPLAY = {
    1 => '  1  '.colorize(:light_white).on_red,
    2 => '  2  '.colorize(:light_white).on_yellow,
    3 => '  3  '.colorize(:light_white).on_green,
    4 => '  4  '.colorize(:light_white).on_blue,
    5 => '  5  '.colorize(:light_white).on_cyan,
    6 => '  6  '.colorize(:light_white).on_magenta
  }.freeze

  CLUE_OPTIONS_DISPLAY = {
    correct_number_correct_position: '●'.colorize(:red),
    correct_number_wrong_position: '○'
  }.freeze

  MAX_TURN_NUMBER = 12
end

# Class - Code-Breaking behavior for the computer
class ComputerCodeBreaker
  attr_accessor :guess, :remaining_possible_codes, :min_scores

  attr_reader :initial_set, :previous_clue
  
  def initialize
    @guess = [1, 1, 2, 2]
    @initial_set = all_possible_codes(1, 6, 4)
    @remaining_possible_codes = initial_set
  end
  
  def get_guess(turn, previous_clue)
    if turn == 1
      guess
    else
      @previous_clue = previous_clue
      eliminate_impossible_codes(remaining_possible_codes)
      self.guess = find_next_guess
    end
  end

  private

  def all_possible_codes(min, max, code_length)
    array = Array(min..max)
    array.repeated_permutation(code_length) { |permutation| array.push(permutation) }
    array -= Array(min..max)
  end

  def eliminate_impossible_codes(array)
    self.remaining_possible_codes = array.select do |code|
      potential_clue = Clue.new(guess, code).return_clues
      potential_clue == previous_clue
    end
  end

  def find_next_guess
    guess_scores = score_potential_guesses
    @min_scores = collect_min_score_codes(guess_scores)
    choose_next_guess
  end

  def score_potential_guesses
    initial_set.each_with_object(Hash.new(0)) do |guess, guess_scores|
      score_count = remaining_possible_codes.each_with_object(Hash.new(0)) do |code, clue_count|
        clue_result = calculate_clue_result(guess, code)
        accumulate_clue_results(clue_count, clue_result)
      end
      guess_scores[guess] = score_count.values.max
    end
  end

  def calculate_clue_result(guess, code)
    Clue.new(guess, code).return_clues
  end

  def accumulate_clue_results(accumulator, clue)
    accumulator[clue] += 1
  end

  def collect_min_score_codes(guess_scores)
    min_score = guess_scores.values.min
    guess_scores.select do |code_key, score_value|
      code_key if score_value == min_score
    end.keys
  end

  def choose_next_guess
    # Pick a member of S(Remaining Possible Codes) whenever possible
    possible_and_min_codes = min_scores & remaining_possible_codes
    possible_and_min_codes.length.positive? ? possible_and_min_codes[0] : min_scores[0]
  end
end

# Class - Code-breaking behavior for the user
class UserCodeBreaker
  include GameText

  attr_reader :guess, :guess_array

  def get_guess(turn, clues)
    get_guess_input
    guess_to_int_array

    if guess_valid?
      guess_array
    else
      puts invalid_guess_warning
      puts user_guess_prompt
      get_guess(turn, clues)
    end
  end

  private

  def get_guess_input
    @guess = gets.chomp
  end

  def guess_to_int_array
    @guess_array = guess.split('').map(&:to_i)
  end

  def guess_valid?
    guess.length == 4 &&
      guess_array.all? { |number| Board::NUMBER_OPTIONS.include?(number) }
  end
end

# Class for the Code Maker (Computer or User)
class CodeMaker
  include GameText

  attr_reader :user_input, :user_input_array, :code

  def get_code(user_role)
    @code = user_role == 'code maker' ? get_user_code : create_computer_code
  end

  private

  def create_computer_code
    Array.new(4) { Board::NUMBER_OPTIONS.sample }
  end
  
  def get_user_code
    get_user_code_input
    user_code_to_int_array
    if user_code_valid?
      user_input_array
    else
      puts invalid_user_code_warning
      get_user_code
    end
  end

  def get_user_code_input
    @user_input = gets.chomp
  end

  def user_code_to_int_array
    @user_input_array = user_input.split('').map(&:to_i)
  end

  def user_code_valid?
    user_input.length == 4 &&
      user_input_array.all? { |number| Board::NUMBER_OPTIONS.include?(number) }
  end
end

# Class - Creates clue feedback objects when given a guess and a code
class Clue
  attr_reader :guess, :code, :common_numbers_count
  attr_accessor :index_hash, :index_clue

  def initialize(guess, code)
    @guess = guess
    @code = code
  end

  def return_clues
    process_guess
    clue_array
    remove_nil_values
  end

  private

  def process_guess
    count_common_numbers
    build_index_hash
    subtract_true_true_values
    evaluate_unknown_numbers
    add_clues
  end

  def common_numbers
    guess & code
  end

  def count_common_numbers
    @common_numbers_count = common_numbers.each_with_object(Hash.new(0)) do |number, hash|
      guess_occurrences = guess.filter { |guess_digit| guess_digit == number }.length
      code_occurrences = code.filter { |code_digit| code_digit == number }.length
      hash[number] = [guess_occurrences, code_occurrences].min
      hash
    end
  end

  def build_index_hash
    @index_hash = guess.each_with_index.each_with_object({}) do |(number, index), hash|
      hash[index] = {}
      hash[index][:guess_value] = number
      hash[index][:code_value] = code[index]
      hash[index][:number_and_position_correct?] = number_and_position_true?(index)
    end
  end
  
  def number_and_position_true?(index)
    guess[index] == code[index]
  end
  
  def subtract_true_true_values
    index_hash.each do |index, hash|
      subtract_from_common_count(guess[index]) if hash[:number_and_position_correct?]
    end
  end

  def evaluate_unknown_numbers
    index_hash.each do |index, hash|
      hash[:number_correct?] = hash[:number_and_position_correct?] ? true : unknown_number_true?(index)
    end
  end

  def unknown_number_true?(index)
    if common_numbers_count[guess[index]] > 0
      subtract_from_common_count(guess[index])
      true
    else
      false
    end
  end

  def subtract_from_common_count(guess_index)
    common_numbers_count[guess_index] -= 1
  end

  def add_clues
    index_hash.each do |_index_key, hash|
      if hash[:number_and_position_correct?]
        hash[:clue_display] = Board::CLUE_OPTIONS_DISPLAY[:correct_number_correct_position]
      elsif hash[:number_correct?]
        hash[:clue_display] = Board::CLUE_OPTIONS_DISPLAY[:correct_number_wrong_position]
      end
    end
  end

  def clue_array
    index_hash.map { |_index_key, hash_value| hash_value[:clue_display] }
  end

  def remove_nil_values
    clue_array.compact
  end
end

# Module - Namespace for functions that handle user role selection
module ChooseGameRole
  def choose_role
    puts choose_role_prompt
    @user_role = user_role_number_to_role
  end

  def user_role_number_input
    gets.chomp.to_i
  end
  
  def user_role_number_to_role
    user_role_number = user_role_number_input
    if user_role_number_valid?(user_role_number)
      assign_role(user_role_number)
    else
      puts invalid_role_number_warning
      user_role_number_to_role
    end
  end

  def user_role_number_valid?(number)
    [1, 2].include?(number)
  end

  def assign_role(number)
    number == 1 ? 'code maker' : 'code breaker'
  end
end

# Game Class - Contains the core game logic
class Game
  include Rules
  include GameText
  include ChooseGameRole

  attr_reader :board, :user_role, :code, :code_breaker, :guess, :clues

  def initialize
    @board = Board.new
    instructions
    choose_role
    play_game
  end

  private

  def play_game
    puts user_code_prompt if user_role == 'code maker'
    initialize_code_maker
    puts computer_code_created if user_role == 'code breaker'
    initialize_code_breaker
    game_loop
    end_of_game
  end

  def initialize_code_maker
    @code = CodeMaker.new.get_code(user_role)
  end

  def initialize_code_breaker
    @code_breaker = user_role == 'code maker' ? ComputerCodeBreaker.new : UserCodeBreaker.new
  end

  def game_loop
    loop do
      puts user_guess_prompt if user_role == 'code breaker'
      @guess = code_breaker.get_guess(board.turn_number, clues)
      @clues = Clue.new(guess, code).return_clues
      display_turn
      board.increment_turn
      break if game_over?
    end
  end
  
  def game_over?
    code_maker_wins? || code_breaker_wins?
  end

  def code_maker_wins?
    board.turn_number > 12
  end

  def code_breaker_wins?
    clues.all? do |clue|
      clue == Board::CLUE_OPTIONS_DISPLAY[:correct_number_correct_position]
    end && clues.length == 4
  end

  def game_winner
    code_breaker_wins? ? 'code breaker' : 'code maker'
  end

  def end_of_game
    end_of_game_message
    puts prompt_replay
    if replay?
      replay_game
    else
      puts 'Thanks for playing!'
    end
  end
  
  def end_of_game_message
    winner = game_winner
    case winner
    when 'code breaker'
      puts user_code_breaker_win if user_role == 'code breaker'
      puts computer_code_breaker_win if user_role == 'code maker'
    when 'code maker'
      if user_role == 'code breaker'
        puts user_code_breaker_loss
        reveal_code
      end
      puts computer_code_breaker_loss if user_role == 'code maker'
    end
  end

  def replay?
    replay_input = gets.chomp.downcase
    replay_input == 'y'
  end

  def replay_game
    Game.new
  end
end

Game.new
