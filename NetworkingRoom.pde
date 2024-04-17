JSONObject networkingData; 
ArrayList<User> networkingUsers = new ArrayList<User>();
User networkingCurrentUser; 
int networkingCurrentUpdateIndex = 0;
int networkingStartTime = 0; 
PImage NetworkingBgImage;

// Audio Setup
import beads.*;
import beads.Reverb;
AudioContext networking_ac;
Gain networkingg1, networkingg2, networkingg3, networkingg4; // Gain for each audio source
SamplePlayer networkingPlayer1, networkingPlayer2, networkingPlayer3, networkingPlayer4; // Each SamplePlayer for audio files
PVector networkingSoundSource1, networkingSoundSource2, networkingSoundSource3; 
Reverb networkingReverb;

// Variables for slider
int sliderX = 590;
int sliderY = 710; // Above the return button
int sliderWidth = 190;
int sliderHeight = 20;
float sliderValue = 1.0; // Default volume level

void initNetworkingRoom() {
  networkingStartTime = millis();
  JSONObject dataFile = loadJSONObject("data.json");
  JSONArray rooms = dataFile.getJSONArray("rooms");
  for (int i = 0; i < rooms.size(); i++) {
    JSONObject room = rooms.getJSONObject(i);
    if (room.getString("roomID").equals("NETWORKING_ROOM")) {
      networkingData = room;
      break;
    }
  }

  networkingCurrentUser = new User("currentUser", 0.5, 0.5);
  JSONArray userPositions = networkingData.getJSONArray("updates").getJSONObject(0).getJSONArray("userPositions");
  for (int i = 0; i < userPositions.size(); i++) {
    JSONObject userPosition = userPositions.getJSONObject(i);
    networkingUsers.add(new User(
      userPosition.getString("userID"), 
      userPosition.getFloat("x"), 
      userPosition.getFloat("y")
    ));
  }
  
  networking_ac = new AudioContext();
  try {
      // Setup for interview 1
      Sample networkingSample1 = new Sample(dataPath("interview1.wav"));
      networkingPlayer1 = new SamplePlayer(networking_ac, networkingSample1);
      networkingg1 = new Gain(networking_ac, 1, 0.5f);
      networkingg1.addInput(networkingPlayer1);
      networking_ac.out.addInput(networkingg1);
      networkingPlayer1.start();

      // Setup for interview 2
      Sample networkingSample2 = new Sample(dataPath("interview2.wav"));
      networkingPlayer2 = new SamplePlayer(networking_ac, networkingSample2);
      networkingg2 = new Gain(networking_ac, 1, 0.5f);
      networkingg2.addInput(networkingPlayer2);
      networkingPlayer2.pause(true);
      networking_ac.out.addInput(networkingg2);
      
      // Setup for interview 3
      Sample networkingSample3 = new Sample(dataPath("interview3.wav"));
      networkingPlayer3 = new SamplePlayer(networking_ac, networkingSample3);
      networkingg3 = new Gain(networking_ac, 1, 0.5f);
      networkingg3.addInput(networkingPlayer3);
      networkingPlayer3.pause(true);
      networking_ac.out.addInput(networkingg3);
      
      // Setup for elevator pitch
      Sample networkingSample4 = new Sample(dataPath("elevatorPitch.mp3"));
      networkingPlayer4 = new SamplePlayer(networking_ac, networkingSample4);
      networkingg4 = new Gain(networking_ac, 1, 1.0f);
      networkingg4.addInput(networkingPlayer4);
      networking_ac.out.addInput(networkingg4);
      networkingPlayer4.start();
      
      
      networking_ac.start();
  } catch(Exception e) {
      println("Error loading audio file: " + e.getMessage());
  }

  // Initialize sound source positions
  networkingSoundSource1 = new PVector(networkingUsers.get(0).position.x, networkingUsers.get(0).position.y);
  networkingSoundSource2 = new PVector(0, 0);
  networkingSoundSource3 = new PVector(0, 0);
  
  // Initialize the Reverb
  networkingReverb = new Reverb(networking_ac);
  networkingReverb.setSize(0.0f);
  networking_ac.out.addInput(networkingReverb); 
}

void drawNetworkingRoom() {
  //background(92,92,92);
  image(NetworkingBgImage, 400, 400);
  
  float maxDistance = dist(0, 0, width, height);

  // Update sound source position for player 2
  if (findUserByID_networking("3") != null) {
    networkingSoundSource2.set(findUserByID_networking("3").position.x, findUserByID_networking("3").position.y);
    //println("Sound source position for player 2 updated to: " + networkingSoundSource2);
  }
  
  if (findUserByID_networking("5") != null) {
    networkingSoundSource3.set(findUserByID_networking("5").position.x, findUserByID_networking("5").position.y);
    //println("Sound source position for player 2 updated to: " + networkingSoundSource2);
  }

  // Adjust audio volume based on distance
  float distance1 = dist(networkingCurrentUser.position.x, networkingCurrentUser.position.y, networkingSoundSource1.x, networkingSoundSource1.y);
  float volume1 = 1.2 / (1.0 + exp((distance1 / maxDistance - 0.3) * 20));
  networkingg1.setGain(volume1);
  //println("Volume 1: " + volume1);
  

  if (networkingSoundSource2 != null) {
    float distance2 = dist(networkingCurrentUser.position.x, networkingCurrentUser.position.y, networkingSoundSource2.x, networkingSoundSource2.y);
    float volume2 = 1.5 / (1.0 + exp((distance2 / maxDistance - 0.3) * 20));
    networkingg2.setGain(volume2);
    //println("Volume 2: " + volume2);
  }
  
  if (networkingSoundSource3 != null) {
    float distance3 = dist(networkingCurrentUser.position.x, networkingCurrentUser.position.y, networkingSoundSource3.x, networkingSoundSource3.y);
    float volume3 = 0.5 / (1.0 + exp((distance3 / maxDistance - 0.2) * 20));
    networkingg3.setGain(volume3);
    //println("Volume 3: " + volume3);
  }
  
  float volume4 = sliderValue * 1f;
  networkingg4.setGain(volume4);
  //println("Volume 4: " + volume4);
 

  int elapsedTime = millis() - networkingStartTime;

  // Dynamically load updates based on elapsedTime
  JSONArray updates = networkingData.getJSONArray("updates");
  for (int i = 0; i < updates.size(); i++) {
    JSONObject update = updates.getJSONObject(i);
    int updateTimestamp = update.getInt("timestamp");

    if (elapsedTime >= updateTimestamp) {
      // Apply this update
      networkingApplyUpdate(update);
    }
  }

  // Draw users and current user
  for (User user : networkingUsers) {
    user.updatePosition();
    user.drawAvatar();
  }
  networkingCurrentUser.updatePosition();
  networkingCurrentUser.drawAvatar();
  drawReturnButton();
  drawVolumeSlider();
  drawChatBox();
}

void networkingApplyUpdate(JSONObject update) {
    int updateTimestamp = update.getInt("timestamp");
    if (updateTimestamp <= networkingCurrentUpdateIndex) {
        return; // This update has already been applied
    }
    networkingCurrentUpdateIndex = updateTimestamp; // Update the current index to the latest applied update


    // Check if the room size has increased
    JSONObject roomSize = update.getJSONObject("roomSize");
    int userCount = roomSize.getInt("userCount");
    
    if (userCount > networkingUsers.size()) {
        networkingReverb.setSize(1 - (userCount * 0.1f));
        //println("reverb val " + networkingReverb.getSize());
    }
    
    if (userCount == 4) {
      networkingPlayer2.start();
      //println("started playing player2");
    }
    
    if (userCount == 6) {
      networkingPlayer3.start();
    }

    JSONArray userPositions = update.getJSONArray("userPositions");
    for (int i = 0; i < userPositions.size(); i++) {
        JSONObject userPosition = userPositions.getJSONObject(i);
        String userID = userPosition.getString("userID");
        float x = userPosition.getFloat("x");
        float y = userPosition.getFloat("y");

        User user = findUserByID_networking(userID);
        if (user != null) {
            if (userPosition.hasKey("movingToX") && userPosition.hasKey("movingToY")) {
                float movingToX = userPosition.getFloat("movingToX");
                float movingToY = userPosition.getFloat("movingToY");
                user.moveTo(movingToX, movingToY); // Update the user's destination
            } else {
                // Directly set the position if there are no destination coordinates
                user.position.set(width * x, height * y);
            }
        } else {
            // New user is being added
            User newUser = new User(userID, x, y);
            networkingUsers.add(newUser);
            if (userPosition.hasKey("movingToX") && userPosition.hasKey("movingToY")) {
                float movingToX = userPosition.getFloat("movingToX");
                float movingToY = userPosition.getFloat("movingToY");
                newUser.moveTo(movingToX, movingToY); // Set the initial movement destination
            }
        }
    }
}

void drawVolumeSlider() {  
  fill(200);
  rect(sliderX, sliderY, sliderWidth, sliderHeight);
  fill(255, 0, 0);
  int knobX = (int) (sliderX + sliderValue * sliderWidth);
  rect(knobX - 5, sliderY, 10, sliderHeight);
  fill(255);
  text("Volume " + String.format("%.2f", sliderValue), sliderX + sliderWidth / 2, sliderY - 10);
}

void resetNetworkingRoom() {
    networkingUsers.clear(); // Clear the existing list of users
    networkingCurrentUpdateIndex = 0; // Reset the current update index
}
