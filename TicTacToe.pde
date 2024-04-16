boolean playingTicTacToe = false;
int[][] ticTacToeBoard = new int[3][3]; // 0 = empty, 1 = X, 2 = O
boolean currentPlayerX = true; // X starts first
int boardX = 20; // X position of the board on the screen
int boardY = 600; // Y position of the board on the screen

// Audio Variables for the board
SamplePlayer ticTacToeSound, gameWinSound;
Gain ticTacToeSoundGain;

void drawTicTacToeBoard() {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            int x = boardX + j * 66;
            int y = boardY + i * 66;
            stroke(255);
            fill(0);
            rect(x, y, 66, 66);
            if (ticTacToeBoard[i][j] == 1) {
                drawX(x, y);
            } else if (ticTacToeBoard[i][j] == 2) {
                drawO(x, y);
            }
        }
    }
}

void drawX(int x, int y) {
    line(x + 10, y + 10, x + 56, y + 56);
    line(x + 56, y + 10, x + 10, y + 56);
}

void drawO(int x, int y) {
    ellipse(x + 33, y + 33, 46, 46);
}

boolean checkWin() {
    int[][] lines = {
        {0, 1, 2}, {3, 4, 5}, {6, 7, 8},  // Rows
        {0, 3, 6}, {1, 4, 7}, {2, 5, 8},  // Columns
        {0, 4, 8}, {2, 4, 6}              // Diagonals
    };
    for (int[] line : lines) {
        if (ticTacToeBoard[line[0] / 3][line[0] % 3] != 0 &&
            ticTacToeBoard[line[0] / 3][line[0] % 3] == ticTacToeBoard[line[1] / 3][line[1] % 3] &&
            ticTacToeBoard[line[1] / 3][line[1] % 3] == ticTacToeBoard[line[2] / 3][line[2] % 3]) {
            return true;
        }
    }
    return false;
}


void resetTicTacToe() {
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            ticTacToeBoard[i][j] = 0;
        }
    }
    currentPlayerX = true;
    
}

void playTicTacToeSound() {
    try {
        Sample ticTacToeSample = new Sample(dataPath("boardgame.wav"));
        ticTacToeSound = new SamplePlayer(game_ac, ticTacToeSample);
        ticTacToeSoundGain = new Gain(game_ac, 1, 0.5f);
        ticTacToeSoundGain.addInput(ticTacToeSound);
        game_ac.out.addInput(ticTacToeSoundGain);

        ticTacToeSound.start(); // Start playing the sound
    } catch (Exception e) {
        println("Failed to reinitialize Tic-Tac-Toe sound: " + e.getMessage());
    }
}

void playWinSound() {
    try {
        Sample winSample = new Sample(dataPath("gameWin.wav"));
        gameWinSound = new SamplePlayer(game_ac, winSample);
        Gain winSoundGain = new Gain(game_ac, 1, 0.8f);  // Adjust volume as needed
        winSoundGain.addInput(gameWinSound);
        game_ac.out.addInput(winSoundGain);
        
        gameWinSound.start();
    } catch (Exception e) {
        println("Failed to reinitialize Tic-Tac-Toe sound: " + e.getMessage());
    }
  
}
