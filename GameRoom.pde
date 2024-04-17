PImage GameBgImage;
JSONObject gameData; 
ArrayList<User> gameUsers = new ArrayList<User>();
User gameCurrentUser; 
int gameCurrentUpdateIndex = 0;
int gameStartTime = 0; 

// Audio Setup
import beads.*;
import beads.Reverb;
AudioContext game_ac;
Gain gameg1, gameg2; // Gain for each audio source
SamplePlayer gamePlayer1, gamePlayer2; // Each SamplePlayer for audio files
PVector gameSoundSource1, gameSoundSource2; 
Reverb gameReverb;

void initGameRoom() {
  gameStartTime = millis();
  JSONObject dataFile = loadJSONObject("data.json");
  JSONArray rooms = dataFile.getJSONArray("rooms");
  for (int i = 0; i < rooms.size(); i++) {
    JSONObject room = rooms.getJSONObject(i);
    if (room.getString("roomID").equals("GAME_ROOM")) {
      gameData = room;
      break;
    }
  }

  gameCurrentUser = new User("currentUser", 0.5, 0.5);
  JSONArray userPositions = gameData.getJSONArray("updates").getJSONObject(0).getJSONArray("userPositions");
  for (int i = 0; i < userPositions.size(); i++) {
    JSONObject userPosition = userPositions.getJSONObject(i);
    gameUsers.add(new User(
      userPosition.getString("userID"), 
      userPosition.getFloat("x"), 
      userPosition.getFloat("y")
    ));
  }
  
  game_ac = new AudioContext();
  try {
      // Setup for various game sounds
      Sample gameSample1 = new Sample(dataPath("gameGroup1.wav"));
      gamePlayer1 = new SamplePlayer(game_ac, gameSample1);
      gameg1 = new Gain(game_ac, 1, 0.5f);
      gameg1.addInput(gamePlayer1);
      game_ac.out.addInput(gameg1);
      gamePlayer1.start();

      Sample gameSample2 = new Sample(dataPath("gameGroup2.wav"));
      gamePlayer2 = new SamplePlayer(game_ac, gameSample2);
      gameg2 = new Gain(game_ac, 1, 0.5f);
      gameg2.addInput(gamePlayer2);
      gamePlayer2.pause(true);
      game_ac.out.addInput(gameg2);
      
      game_ac.start();
  } catch(Exception e) {
      println("Error loading audio file: " + e.getMessage());
  }

  // Initialize sound source positions
  gameSoundSource1 = new PVector(gameUsers.get(0).position.x, gameUsers.get(0).position.y);
  gameSoundSource2 = new PVector(0, 0);
  
  // Initialize the Reverb
  gameReverb = new Reverb(game_ac);
  gameReverb.setSize(0.0f);
  game_ac.out.addInput(gameReverb); 
}

void drawGameRoom() {
  image(GameBgImage, 400,400);  // Stretch the background image to fill the screen

  float maxDistance = dist(0, 0, width, height);
  
  // Update sound source position for player 2
  if (findUserByID_game("3") != null) {
    gameSoundSource2.set(findUserByID_game("3").position.x, findUserByID_game("3").position.y);
    //println("Sound source position for player 2 updated to: " + gameSoundSource2);
  }
  

  // Adjust audio volumes based on distance to the sound sources
  if (gameSoundSource1 != null) {
    float distance1 = dist(gameCurrentUser.position.x, gameCurrentUser.position.y, gameSoundSource1.x, gameSoundSource1.y);
    float volume1 = 0.7 / (1.0 + exp((distance1 / maxDistance - 0.15) * 20));
    gameg1.setGain(volume1);
  }
  
  if (gameSoundSource2 != null) {
    float distance2 = dist(gameCurrentUser.position.x, gameCurrentUser.position.y, gameSoundSource2.x, gameSoundSource2.y);
    float volume2 = 0.7 / (1.0 + exp((distance2 / maxDistance - 0.15) * 20));
    gameg2.setGain(volume2);
  }

  int elapsedTime = millis() - gameStartTime;

  // Dynamically load updates based on elapsedTime
  JSONArray updates = gameData.getJSONArray("updates");
  for (int i = 0; i < updates.size(); i++) {
    JSONObject update = updates.getJSONObject(i);
    int updateTimestamp = update.getInt("timestamp");

    if (elapsedTime >= updateTimestamp) {
      gameApplyUpdate(update);
    }
  }

  // Draw users and current user
  for (User user : gameUsers) {
    user.updatePosition();
    user.drawAvatar();
  }
  gameCurrentUser.updatePosition();
  gameCurrentUser.drawAvatar();
  drawReturnButton();
  drawTicTacToeButton();
  if (playingTicTacToe) {
    drawTicTacToeBoard();
  }
  drawChatBox();
}


void gameApplyUpdate(JSONObject update) {
    int updateTimestamp = update.getInt("timestamp");
    if (updateTimestamp <= gameCurrentUpdateIndex) {
        return; // This update has already been applied
    }
    gameCurrentUpdateIndex = updateTimestamp; // Update the current index to the latest applied update

    JSONObject roomSize = update.getJSONObject("roomSize");
    int userCount = roomSize.getInt("userCount");

    if (userCount > gameUsers.size()) {
        gameReverb.setSize(1 - (userCount * 0.1f));
    }
    
    if (userCount == 4) {
      gamePlayer2.start();
      //println("started playing player2");
    }

    JSONArray userPositions = update.getJSONArray("userPositions");
    for (int i = 0; i < userPositions.size(); i++) {
        JSONObject userPosition = userPositions.getJSONObject(i);
        String userID = userPosition.getString("userID");
        float x = userPosition.getFloat("x");
        float y = userPosition.getFloat("y");

        User user = findUserByID_game(userID);
        if (user != null) {
            if (userPosition.hasKey("movingToX") && userPosition.hasKey("movingToY")) {
                float movingToX = userPosition.getFloat("movingToX");
                float movingToY = userPosition.getFloat("movingToY");
                user.moveTo(movingToX, movingToY); // Update the user's destination
            } else {
                user.position.set(width * x, height * y);
            }
        } else {
            User newUser = new User(userID, x, y);
            gameUsers.add(newUser);
            if (userPosition.hasKey("movingToX") && userPosition.hasKey("movingToY")) {
                float movingToX = userPosition.getFloat("movingToX");
                float movingToY = userPosition.getFloat("movingToY");
                newUser.moveTo(movingToX, movingToY); // Set the initial movement destination
            }
        }
    }
}

void drawTicTacToeButton() {
    fill(255);
    rect(width - 210, height - 120, 200, 50, 5);
    fill(0);
    textSize(16);
    if (playingTicTacToe) {
        text("Exit Tic-Tac-Toe", width - 110, height - 95);
    } else {
        text("Play Tic-Tac-Toe", width - 110, height - 95);
    }
}

void resetGameRoom() {
    gameUsers.clear(); // Clear the existing list of users
    gameCurrentUpdateIndex = 0; // Reset the current update index
}
