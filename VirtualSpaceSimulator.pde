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

//// Voice and TTS setup
import com.sun.speech.freetts.*;
private VoiceManager vm;
private Voice voice;

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
  
  // Setup FreeTTS
  System.setProperty("freetts.voices",
      "com.sun.speech.freetts.en.us.cmu_us_kal.KevinVoiceDirectory");
  vm = VoiceManager.getInstance();
  voice = vm.getVoice("kevin16");

  if (voice != null) {
      voice.allocate();
  }
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
    // Log mouse interaction for debugging and analysis
    String logEntry = "Timestamp: " + millis() + ", MouseX: " + mouseX + ", MouseY: " + mouseY + ", CurrentScenario: " + currentScenario;
    interactionLogs.append(logEntry);

    // UI interaction checks
    if (mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 60 && mouseY < height - 10) {
        // 'Return to Main Menu' button
        currentScenario = NONE;
        background(0, 0, 0); 
        stopAudio();
        playingTicTacToe = false;
        resetTicTacToe();
        return; // Ensure no further processing is done
    }

    // Scenario-specific button interactions
    switch (currentScenario) {
        case PARTY_ROOM:
            if (mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 120 && mouseY < height - 70) {
                toggleSpeakerFocus();
                return;
            }
            break;
        case GAME_ROOM:
            if (currentScenario == GAME_ROOM && mouseX > width - 210 && mouseX < width - 10 && mouseY > height - 120 && mouseY < height - 70) {
                playingTicTacToe = !playingTicTacToe; // Toggle the state of Tic-Tac-Toe
                if (!playingTicTacToe) {
                    resetTicTacToe();
                }
                return; // Prevent further interactions in the same click
            }
            if (playingTicTacToe && mouseX > boardX && mouseX < boardX + 200 && mouseY > boardY && mouseY < boardY + 200) {
                int col = (mouseX - boardX) / 66;
                int row = (mouseY - boardY) / 66;
                if (ticTacToeBoard[row][col] == 0) {
                    ticTacToeBoard[row][col] = currentPlayerX ? 1 : 2;
                    currentPlayerX = !currentPlayerX;  // Toggle player turn
                    playTicTacToeSound();
                    if (checkWin()) {
                        playWinSound();
                        resetTicTacToe();
                    }
                }
                return;
            }
            break;
        case NETWORKING_ROOM:
            if (mouseX > sliderX && mouseX < sliderX + sliderWidth && mouseY > sliderY && mouseY < sliderY + sliderHeight) {
                sliderValue = (float)(mouseX - sliderX) / sliderWidth;
                return;
            }
            break;
    }

    // Chatbox and Speak button interaction in any room
    if (isChatBoxFocused) {
        if (mouseX > 460 && mouseX < 560 && mouseY > height - 50 && mouseY < height - 10) {
            speakText(chatText);
            chatText = "";  // Clear the chat bar after speaking
            isChatBoxFocused = false; // Optionally unfocus chatbox after speaking
            return;
        } else if (mouseX > 50 && mouseX < 450 && mouseY > height - 50 && mouseY < height - 10) {
            // Focuses the chatbox but does not block further interactions unless this is the intended behavior
            return;
        }
    } else if (mouseX > 50 && mouseX < 450 && mouseY > height - 50 && mouseY < height - 10) {
        isChatBoxFocused = true;
        return;
    }

    // Scenario switching buttons
    if (currentScenario == NONE) {
        for (int i = 0; i < labels.length; i++) {
            int y = startY + i * (buttonHeight + gap);
            if (mouseX > startX && mouseX < startX + buttonWidth && mouseY > y && mouseY < y + buttonHeight) {
                switch (i) {
                    case 0: // Party Room
                        currentScenario = PARTY_ROOM;
                        resetPartyRoom();
                        initPartyRoom();
                        break;
                    case 1: // Networking Room
                        currentScenario = NETWORKING_ROOM;
                        resetNetworkingRoom();
                        initNetworkingRoom();
                        break;
                    case 2: // Game Room
                        currentScenario = GAME_ROOM;
                        resetGameRoom();
                        initGameRoom();
                        break;
                }
                return; // Stop further processing after switching scenarios
            }
        }
    }

    // Game movements, should not trigger if UI elements were interacted with
    if (!isChatBoxFocused && currentScenario != NONE) {
        updateUserPosition(mouseX, mouseY);
    }
}

void updateUserPosition(int x, int y) {
    // Update user position based on the scenario
    switch(currentScenario) {
        case PARTY_ROOM:
            partyCurrentUser.moveTo(x / (float)width, y / (float)height);
            break;
        case NETWORKING_ROOM:
            networkingCurrentUser.moveTo(x / (float)width, y / (float)height);
            break;
        case GAME_ROOM:
            gameCurrentUser.moveTo(x / (float)width, y / (float)height);
            break;
    }
}


void keyPressed() {
    if (!isChatBoxFocused) {
        return; // Ignore keystrokes when chatbox is not focused
    }

    if (keyCode == BACKSPACE) {
        if (chatText.length() > 0) {
            chatText = chatText.substring(0, chatText.length() - 1);
        }
    } else if (keyCode == ENTER || keyCode == RETURN) {
        // Optionally handle sending message on Enter
        speakText(chatText);
        chatText = ""; // Clear the chat after sending
        isChatBoxFocused = false; // Optionally unfocus chatbox after sending
    } else {
        chatText += key;
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

void listVoices() {
    VoiceManager voiceManager = VoiceManager.getInstance();
    Voice[] voices = voiceManager.getVoices();
    for (Voice v : voices) {
        println("Voice Name: " + v.getName());
    }
}
