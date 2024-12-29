#!/bin/bash

# Define the PSQL command with preset options for database connection
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random secret number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Function to prompt for and validate the username
ASK_USERNAME() {
  echo -e "\nEnter your username:"
  read USERNAME

  # Validate that the username is between 1 and 22 characters
  USERNAME_LENGTH=${#USERNAME}
  if [[ $USERNAME_LENGTH -gt 22 || $USERNAME_LENGTH -lt 1 ]]; then
    echo "Invalid username. It must be between 1 and 22 characters."
    ASK_USERNAME  # Recursively prompt for username again
  fi
}

# Prompt the user for their username
ASK_USERNAME

# Check if the user already exists in the database
RETURNING_USER=$($PSQL "SELECT username FROM users WHERE username = '$USERNAME'")
if [[ -z $RETURNING_USER ]]; then
  # If the user does not exist, insert a new user record
  INSERTED_USER=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME')")
  echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
else
  # If the user exists, retrieve their stats
  GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games INNER JOIN users USING(user_id) WHERE username = '$USERNAME'")
  BEST_GAME=$($PSQL "SELECT MIN(num_guess) FROM games INNER JOIN users USING(user_id) WHERE username = '$USERNAME'")
  echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Retrieve the user ID for the current username
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")

# Initialize game variables: number of attempts (TRIES) and the user's guess
TRIES=0
GUESS=0

# Start the guessing game
echo -e "\nGuess the secret number between 1 and 1000:"

while true; do
  # Read the user's guess
  read GUESS

  # Check if the input is a valid integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue  # Skip the rest of the loop and prompt again
  fi

  # Increment the number of attempts
  TRIES=$((TRIES + 1))

  # Check if the guess matches the secret number
  if [[ $GUESS -eq $SECRET_NUMBER ]]; then
    # If correct, display success message and record the game
    echo -e "\nYou guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
    $PSQL "INSERT INTO games (user_id, num_guess) VALUES ($USER_ID, $TRIES)"
    break  # Exit the loop
  elif [[ $GUESS -lt $SECRET_NUMBER ]]; then
    # If the guess is too low, provide a hint
    echo "It's higher than that, guess again:"
  else
    # If the guess is too high, provide a hint
    echo "It's lower than that, guess again:"
  fi
done
