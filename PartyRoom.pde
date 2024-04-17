JSONObject partyData; 
ArrayList<User> partyUsers = new ArrayList<User>();
User partyCurrentUser; 
int partyCurrentUpdateIndex = 0;
int partyStartTime = 0; 
PImage PartyBgImage;

// Audio Setup
import beads.*;
import beads.Reverb;
AudioContext party_ac;
Gain partyg1, partyg2, partyg3; // Gain for each audio source
SamplePlayer partyPlayer1, partyPlayer2, partyPlayer3; // Each SamplePlayer for audio files
PVector partySoundSource1, partySoundSource2; 
Reverb partyReverb;
boolean isBirthdayToastPlaying = false;
long birthdayToastStartTime = 0; // Variable to store the start time of the audio


void initPartyRoom() {
  partyStartTime = millis();
  JSONObject dataFile = loadJSONObject("data.json");
  JSONArray rooms = dataFile.getJSONArray("rooms");
  for (int i = 0; i < rooms.size(); i++) {
    JSONObject room = rooms.getJSONObject(i);
    if (room.getString("roomID").equals("PARTY_ROOM")) {
      partyData = room;
      break;
    }
  }

  partyCurrentUser = new User("currentUser", 0.5, 0.5);
  JSONArray userPositions = partyData.getJSONArray("updates").getJSONObject(0).getJSONArray("userPositions");
  for (int i = 0; i < userPositions.size(); i++) {
    JSONObject userPosition = userPositions.getJSONObject(i);
    partyUsers.add(new User(
      userPosition.getString("userID"), 
      userPosition.getFloat("x"), 
      userPosition.getFloat("y")
    ));
  }

  
  party_ac = new AudioContext();
  try {
      // Setup for partyGroup1.wav
      Sample sample1 = new Sample(dataPath("partyGroup1.wav"));
      partyPlayer1 = new SamplePlayer(party_ac, sample1);
      partyg1 = new Gain(party_ac, 1, 0.5f);
      partyg1.addInput(partyPlayer1);
      party_ac.out.addInput(partyg1);
      partyPlayer1.start();

      // Setup for partyGroup2.wav
      Sample sample2 = new Sample(dataPath("partyGroup2.wav"));
      partyPlayer2 = new SamplePlayer(party_ac, sample2);
      partyg2 = new Gain(party_ac, 1, 0.5f);
      partyg2.addInput(partyPlayer2);
      partyPlayer2.pause(true);
      party_ac.out.addInput(partyg2);
      
      Sample birthdayToastSample = new Sample(dataPath("birthdayToast.wav"));
      partyPlayer3 = new SamplePlayer(party_ac, birthdayToastSample);
      partyg3 = new Gain(party_ac,1,0f);
      partyg3.addInput(partyPlayer3);
      partyPlayer3.pause(true);
      party_ac.out.addInput(partyg3);

      party_ac.start();
  } catch(Exception e) {
      println("Error loading audio file: " + e.getMessage());
  }

  // Initialize sound source positions
  partySoundSource1 = new PVector(partyUsers.get(0).position.x, partyUsers.get(0).position.y);
  partySoundSource2 = new PVector(0, 0);
  
  // Initialize the Reverb
  partyReverb = new Reverb(party_ac);
  partyReverb.setSize(0.0f);
  party_ac.out.addInput(partyReverb); 
}


void drawPartyRoom() {
  updateAudioState();
  //background(209, 37, 158); // Clear the screen
  image(PartyBgImage, 400, 400);
  drawSpeakerFocusButton();
  
  float maxDistance = dist(0, 0, width, height);

  // Update sound source position for player 2
  if (findUserByID_party("4") != null) {
    partySoundSource2.set(findUserByID_party("4").position.x, findUserByID_party("4").position.y);
    //println("Sound source position for player 2 updated to: " + soundSourcePosition2);
  }

  // Adjust audio volume based on distance
  if (partySoundSource1 != null) {
    float distance1 = dist(partyCurrentUser.position.x, partyCurrentUser.position.y, partySoundSource1.x, partySoundSource1.y);
    float volume1 = 0.9 / (1.0 + exp((distance1 / maxDistance - 0.2) * 20));
    partyg1.setGain(volume1);
    if (isBirthdayToastPlaying == true) {
      volume1 -= 0.5;
      partyg1.setGain(volume1);
    }
    //println("Volume 1: " + volume1);
  }

  if (partySoundSource2 != null) {
    float distance2 = dist(partyCurrentUser.position.x, partyCurrentUser.position.y, partySoundSource2.x, partySoundSource2.y);
    float volume2 = 1.0 / (1.0 + exp((distance2 / maxDistance - 0.3) * 20));
    partyg2.setGain(volume2);
    if (isBirthdayToastPlaying == true) {
      volume2 -= 0.5;
      partyg2.setGain(volume2);
    }
    //println("Volume 2: " + volume2);
  }
 

  int elapsedTime = millis() - partyStartTime;

  // Dynamically load updates based on elapsedTime
  JSONArray updates = partyData.getJSONArray("updates");
  for (int i = 0; i < updates.size(); i++) {
    JSONObject update = updates.getJSONObject(i);
    int updateTimestamp = update.getInt("timestamp");

    if (elapsedTime >= updateTimestamp) {
      // Apply this update
      partyApplyUpdate(update);
    }
  }

  // Draw users and current user
  for (User user : partyUsers) {
    user.updatePosition();
    user.drawAvatar();
  }
  partyCurrentUser.updatePosition();
  partyCurrentUser.drawAvatar();

  drawReturnButton();
  drawChatBox();
}


void partyApplyUpdate(JSONObject update) {
    int updateTimestamp = update.getInt("timestamp");
    if (updateTimestamp <= partyCurrentUpdateIndex) {
        return; // This update has already been applied
    }
    partyCurrentUpdateIndex = updateTimestamp; // Update the current index to the latest applied update


    // Check if the room size has increased
    JSONObject roomSize = update.getJSONObject("roomSize");
    int userCount = roomSize.getInt("userCount");
    if (userCount > partyUsers.size()) {
        partyReverb.setSize(1 - (userCount * 0.1f));
        //println("reverb val " + partyReverb.getSize());
    }
    
    if (userCount == 4) {
      partyPlayer2.start();
    }

    JSONArray userPositions = update.getJSONArray("userPositions");
    for (int i = 0; i < userPositions.size(); i++) {
        JSONObject userPosition = userPositions.getJSONObject(i);
        String userID = userPosition.getString("userID");
        float x = userPosition.getFloat("x");
        float y = userPosition.getFloat("y");

        User user = findUserByID_party(userID);
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
            partyUsers.add(newUser);
            if (userPosition.hasKey("movingToX") && userPosition.hasKey("movingToY")) {
                float movingToX = userPosition.getFloat("movingToX");
                float movingToY = userPosition.getFloat("movingToY");
                newUser.moveTo(movingToX, movingToY); // Set the initial movement destination
            }
        }
    }
}

void drawSpeakerFocusButton() {
    fill(255); // Button color
    rect(width - 210, height - 120, 200, 50, 5);
    fill(0);
    textSize(16);
    noStroke();
    text("Speaker Focus", width - 110, height - 95);
}

void toggleSpeakerFocus() {
    // Stop the current playback and reset if it was already playing
    partyPlayer3.pause(true);
    partyPlayer3.setPosition(0); // Reset the sample player to start of the audio

    // Start playing the birthday toast audio
    partyPlayer3.start();
    partyg3.setGain(1.0f); 

    // Set flags and print status
    isBirthdayToastPlaying = true;
    birthdayToastStartTime = millis(); // Record the start time
    //println("Speaker Focus Activated: birthdayToast.wav is now playing from the start.");
}

void updateAudioState() {
    if (isBirthdayToastPlaying && (millis() - birthdayToastStartTime) >= 4100) { // Check if 4 seconds have elapsed
        isBirthdayToastPlaying = false; // Reset the flag
        partyPlayer3.pause(true);
        partyPlayer3.setPosition(0);
        //println("birthdayToast.wav playback interval completed.");
    }
}

void resetPartyRoom() {
    partyUsers.clear(); // Clear the existing list of users
    partyCurrentUpdateIndex = 0; // Reset the current update index
}
