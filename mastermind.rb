# frozen_string_literal: true
require 'pry'
require 'colorize'

# Module containing the rules that are displayed at the start of the game
module Rules
  def instructions
    how_to_play
    how_to_play_clues
    how_to_play_start
  end

  def how_to_play
    puts "\n#{"How to play Mastermind".bold}\n\n"
    puts 'This is a 1-player game played against the computer.'
    puts "You can choose to either be the #{'Code Maker'.bold} or the #{'Code Breaker'.bold}."
    puts 'There are 6 different number options:'
    display_number_options
    puts 'The Code Maker will choose 4 random numbers to create a code. For example:'
    display_code_example(1, 3, 4, 1)
    puts 'The Code Breaker will try to guess the code within 12 turns.'
  end

  def how_to_play_clues
    puts "\n#{"Clues".bold}\n\n"
    puts 'After every guess, the Code Maker will provide you with up to 4 clues.'
    display_clue_options
    puts "\n#{"Clue Example".bold}\n\n"
    puts "For example: Guessing '1463' will produce 3 clues:"
    display_code_example(1, 4, 6, 3)
    display_clue_example
  end
  
  def how_to_play_start
    puts 'Time to play!'
    puts "\n"
  end
  
  private

  def display_number_options
    puts "\n"
    Board::NUMBER_OPTIONS_DISPLAY.each { |number, number_display| print number_display + ' ' }
    puts "\n\n"
  end
  
  def display_code_example(number_1, number_2, number_3, number_4)
    puts "\n"
    [number_1, number_2, number_3, number_4].each { |number| print Board::NUMBER_OPTIONS_DISPLAY[number] + ' ' }
    puts "\n\n"
  end

  def display_clue_options
    puts "\n"
    print Board::CLUE_OPTIONS_DISPLAY[:correct_number_correct_position] + "  "
    puts "A #{'red dot'.colorize(:red)} indicates that your guess contains 1 correct number in the correct position."
    print Board::CLUE_OPTIONS_DISPLAY[:correct_number_wrong_position] + "  "
    puts 'An empty dot indicates that your guess contains 1 correct number, but in the wrong position.'
    puts "\n"
  end
  def display_clue_example
    
  end
end

# Module for displaying game text
module GameText
  def computer_code_created
    "The computer has chosen its 4-digit code."
  end

  def prompt_guess
    "Please enter your guess:"
  end

  def invalid_guess_warning
    "Your guess should be a 4-digit number (each digit should be between 1-6):".colorize(:red).bold
  end
end

class Board
  def initialize
    @turn_number = 0
  end
  NUMBER_OPTIONS = [1,2,3,4,5,6]
  NUMBER_OPTIONS_DISPLAY = {
    1 => "#{'  1  '.colorize(:light_white).on_red}",
    2 => "#{'  2  '.colorize(:light_white).on_yellow}",
    3 => "#{'  3  '.colorize(:light_white).on_green}",
    4 => "#{'  4  '.colorize(:light_white).on_blue}",
    5 => "#{'  5  '.colorize(:light_white).on_cyan}",
    6 => "#{'  6  '.colorize(:light_white).on_magenta}"
  }
  CLUE_OPTIONS_DISPLAY = {
    correct_number_correct_position: "#{'●'.colorize(:red)}",
    correct_number_wrong_position: "○"
  } 
  MAX_TURN_NUMBER = 12
end




# If the computer is the Code Breaker
class ComputerCodeBreaker
  
end




# If the user is the Code Breaker
class UserCodeBreaker
  include GameText

  def get_guess
    get_guess_input
    guess_to_int_array
    until guess_valid?
      puts invalid_guess_warning
      puts prompt_guess
      get_guess
    end
    return guess_array
  end

  private

  def get_guess_input
    @guess = gets.chomp
  end

  attr_reader :guess, :guess_array
  
  def guess_to_int_array
    @guess_array = guess.split('').map do |number|
      number.to_i
    end
  end

  def guess_valid?
    @guess.length == 5 &&
      guess_array.all? { |number| Board::NUMBER_OPTIONS.include?(number) }
  end
end




class CodeMaker
  def initialize
    create_computer_code
  end

  attr_reader :computer_code, :user_code

  def create_computer_code
    #@computer_code = Array.new(4) { Board::NUMBER_OPTIONS.sample }
    @computer_code = [1, 3, 4, 1, 5]
  end
  
  def get_user_code
    @user_code = gets.chomp
  end
end


#Class for clue instances and logic
class Clue
  attr_reader :guess, :code, :common_numbers_count, :matching_indexes, :true_true_indexes, :true_unknown_indexes

  def initialize(guess, code)
    @guess = guess
    @code = code
    @clues_hash = {}
    return_clues
  end

  private
  
  def return_clues
    process_input
  end

  def process_input
    common_numbers_occurrences
    indexes_number_true_position_true?
    number_true_position_true
    number_true_position_unknown


    subtract_true_trues
  end

  def common_numbers
    guess & code
  end

  def common_numbers_occurrences
    @common_numbers_count = common_numbers.reduce(Hash.new(0)) do |hash, number|
      guess_occurrences = guess.filter { |guess_digit| guess_digit == number }.length
      code_occurrences = code.filter { |code_digit| code_digit == number }.length
      hash[number] = [guess_occurrences, code_occurrences].min
      hash
    end
  end

  def indexes_number_true_position_true?
    # does each index in the guess match both number and position?
    @matching_indexes = guess.each_with_index.reduce(Hash.new(0)) do |hash, (number, index)|
      hash[index] = guess[index] == code[index]
      hash
    end
  end

  def number_true_position_true
    @true_true_indexes = matching_indexes.select do |index_key, boolean_value|
      boolean_value == true
    end
  end

  def number_true_position_unknown
    @true_unknown_indexes = matching_indexes.select do |index_key, boolean_value|
      boolean_value == false
    end
  end
  
  def subtract_true_trues
    true_true_indexes.each do |index_key, boolean_value|
      subtract_from_common_count(guess[index_key])
      
      
    end
  end

  def subtract_from_common_count(guess_index)
    common_numbers_count[guess_index] -= 1
    binding.pry
  end

end

class Game
  include Rules
  include GameText
  

  attr_reader :code, :code_breaker, :guess

  def initialize
    board = Board.new
    instructions
    choose_role

    initialize_code
    puts computer_code_created
    initialize_code_breaker
    puts prompt_guess

    game_loop
  end

  private

  def choose_role

  end

  def initialize_code
    @code = CodeMaker.new.computer_code
  end

  def initialize_code_breaker
    @code_breaker = UserCodeBreaker.new
  end
  
  def get_guess
    code_breaker.get_guess
    
  end

  def game_loop
    @guess = get_guess
    @clues = Clue.new(guess, code)
  end
 
end

Game.new
