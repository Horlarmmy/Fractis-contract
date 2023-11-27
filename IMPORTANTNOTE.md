matchPaths function in NFTMarketplace :
    This function is like a game where you have to arrange your numbers in order from 1 to 9.

    The function matchPaths takes a list of 9 numbers and checks if they are in the right order. Here's how it works:

    It starts with the first number (at position 0 in the list) and checks if it is 1. If not, it immediately stops and says "No, you didn't win". This is like saying "Game over" when the first number isn't 1.
    If the first number is 1, it moves to the next number (at position 1 in the list) and checks if it is 2. If not, it stops and says "No, you didn't win".
    It keeps doing this for each number in the list. If it finds a number that isn't the next number in the sequence, it stops and says "No, you didn't win".
    If it checks all the numbers and they are all in the right order, it says "Yes, you won". This is like saying "Congratulations, you've won the game" when all the numbers are in the right order.