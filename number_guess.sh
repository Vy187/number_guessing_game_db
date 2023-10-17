#!/bin/bash

# variable to query database
PSQL="psql --username=freecodecamp --dbname=number_guess --tuples-only -c"

# global variables for game to use
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=1

# prompt for username
echo -e "Enter your username:"
read USERNAME

# get user information
USERNAME_RESULT=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME'")

if [[ -z $USERNAME_RESULT ]]
then
  # if user not found then greet them and add them to the database
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here.\n"
  INSERT_USERNAME=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME')") 
else
  # if user is found get their inforation and give a warm welcoming
  GAMES_PLAYED=$($PSQL "SELECT COUNT(game_id) FROM games JOIN users USING(user_id) WHERE username='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT MIN(guesses) FROM games JOIN users USING(user_id) WHERE username='$USERNAME'")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses.\n" | sed -r 's/  */ /g'
fi

# prompt first guess
echo "Guess the secret number between 1 and 1000:"
read GUESS

# loop prompts until guess is eqaul to the secret number
until [[ $GUESS == $SECRET_NUMBER ]]
do
  ((GUESS_COUNT++))
  # path user to the right prompt of the guess
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo -e "That is not an integer, guess again:"
    read GUESS
  else
    if [[ $GUESS -lt $SECRET_NUMBER ]]
    then
      echo -e "It's higher than that, guess again:"
      read GUESS
    else 
      echo -e "It's lower than that, guess again:"
      read GUESS
    fi  
  fi
done

# insert the results to the database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, guesses) VALUES ($USER_ID, $GUESS_COUNT)")

# winning message
echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
