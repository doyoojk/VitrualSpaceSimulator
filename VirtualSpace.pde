// Define scenarios
final int NONE = 0, PARTY_ROOM = 1, NETWORKING_ROOM = 2, GAME_ROOM = 3;
int currentScenario = NONE;

StringList interactionLogs = new StringList();

// Button properties
int buttonWidth = 200;
int buttonHeight = 50;
int startX = 300; 
int startY = 250; 
int gap = 60; 

String[] labels = {"Party Room", "Networking Room", "Game Room"};

void setup() {
  size(800, 800);
  background(0,0,0);
  PartyBgImage = loadImage("party.jpg");
  PartyBgImage.resize(800,800);
  NetworkingBgImage = loadImage("networking.jpg");
  NetworkingBgImage.resize(800,800);
  GameBgImage = loadImage("game.jpg");
  GameBgImage.resize(800,800);
  textAlign(CENTER, CENTER);
}

void draw() {
  switch (currentScenario) {
    case PARTY_ROOM:
      drawPartyRoom();
      break;
    case NETWORKING_ROOM:
      drawNetworkingRoom();
      break;
    case GAME_ROOM:
      drawGameRoom();
      break;
    default:
    
      fill(255);
      textSize(20);
      text("Select a Room to Enter:", 400,200);
      // Draw the main menu
      drawButtons();
      break;
  }
}

void drawButtons() {
  for (int i = 0; i < labels.length; i++) {
    int y = startY + i * (buttonHeight + gap);
    fill(255);
    rect(startX, y, buttonWidth, buttonHeight, 10); 
    fill(0);
    noStroke();
    textSize(16);
    text(labels[i], startX + buttonWidth / 2, y + buttonHeight / 2);
  }
}

void drawReturnButton() {
  fill(255, 255, 255); // Button color
  rect(width - 210, height - 60, 200, 50, 5); 
  fill(0); 
  textSize(16);
  noStroke();
  text("Return to Main Menu", width - 110, height - 35);
}


void mousePressed() {
  // Log mouse interaction
  String logEntry = "Timestamp: " + millis() + ", MouseX: " + mouseX + ", MouseY: " + mouseY + ", CurrentScenario: " + currentScenario;
  interactionLogs.append(logEntry);
  
  if (currentScenario != NONE && mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 60 && mouseY < height - 10) {
    currentScenario = NONE; // Return to main menu
    background(0, 0, 0); 
    stopAudio();
    playingTicTacToe = false;
    resetTicTacToe();
    
  } else if (currentScenario == PARTY_ROOM && mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 120 && mouseY < height - 70){
    toggleSpeakerFocus();
  } else if (currentScenario == NETWORKING_ROOM && mouseX > sliderX && mouseX < sliderX + sliderWidth && mouseY > sliderY && mouseY < sliderY + sliderHeight){
    sliderValue = (float)(mouseX - sliderX) / sliderWidth;
  } else if (currentScenario == GAME_ROOM && mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 120 && mouseY < height - 70) {
    playingTicTacToe = !playingTicTacToe;
      if (!playingTicTacToe) {
          resetTicTacToe();
      }
  } else if (playingTicTacToe) {
    // Check if click is within the Tic-Tac-Toe board bounds
    if (mouseX > boardX && mouseX < boardX + 200 && mouseY > boardY && mouseY < boardY + 200) {
        int col = (mouseX - boardX) / 66;
        int row = (mouseY - boardY) / 66;
        if (ticTacToeBoard[row][col] == 0) {
            ticTacToeBoard[row][col] = currentPlayerX ? 1 : 2;
            currentPlayerX = !currentPlayerX;  // Toggle player turn
            playTicTacToeSound();
            // Check for win after move
            if (checkWin()) {
              playWinSound();
        
              resetTicTacToe();
            }
        }
    } else if (!(mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 60 && mouseY < height - 10)) {
      gameCurrentUser.moveTo(mouseX / (float)width, mouseY / (float)height);
    }
  } else if (currentScenario == PARTY_ROOM && !(mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 60 && mouseY < height - 10)) {
    partyCurrentUser.moveTo(mouseX / (float)width, mouseY / (float)height);
  } else if (currentScenario == GAME_ROOM && !(mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 60 && mouseY < height - 10)){
    gameCurrentUser.moveTo(mouseX / (float)width, mouseY / (float)height);
  } else if (currentScenario == NETWORKING_ROOM && !(mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 60 && mouseY < height - 10)) {
    networkingCurrentUser.moveTo(mouseX / (float)width, mouseY / (float)height);
  } else if (currentScenario == NONE) {
    for (int i = 0; i < labels.length; i++) {
      int y = startY + i * (buttonHeight + gap);
      if (mouseX > startX && mouseX < startX + buttonWidth && mouseY > y && mouseY < y + buttonHeight) {
        // Button i is pressed
        switch (i) {
          case 0: // Party Room
            println("Party Room Selected");
            currentScenario = PARTY_ROOM;
            resetPartyRoom();
            initPartyRoom();
            break;
          case 1: // Networking Room
            println("Networking Room Selected");
            currentScenario = NETWORKING_ROOM;
            resetNetworkingRoom();
            initNetworkingRoom();
            break;
          case 2: // Game Room
            println("Game Room Selected");
            currentScenario = GAME_ROOM;
            resetGameRoom();
            initGameRoom();
            break;
        }
      }
    }
  }
}

void stopAudio() {
    if (party_ac != null) {
        party_ac.stop();  // Stops the audio context, halting all audio processing
    }
    if (networking_ac != null) {
        networking_ac.stop();  
    }
    
    if (game_ac != null) {
      game_ac.stop();
    }
    
}


void exit() {
  String[] logsArray = interactionLogs.toArray(new String[0]); // Convert to String array
  saveStrings(dataPath("interactionLogs.txt"), logsArray);
  
  super.exit();
}
