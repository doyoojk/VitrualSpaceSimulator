class User {
  PVector position;
  PVector destination;
  PImage avatarImage;
  String userID;
  float speed = 4; // You can adjust this speed as necessary
  
  User(String userID, float x, float y) {
    this.userID = userID;
    this.position = new PVector(width * x, height * y); // Assuming x and y are normalized [0, 1]
    this.destination = new PVector(position.x, position.y); // Initial destination is current position
    this.avatarImage = loadImage("avatar.png"); // Assuming all users use the same avatar image
    this.avatarImage.resize(90, 0); // Resize the avatar image
  }
  
  void updatePosition() {
    if (!position.equals(destination)) {
      PVector moveDirection = PVector.sub(destination, position);
      moveDirection.setMag(speed);
      position.add(moveDirection);
      // Ensure the user does not overshoot the destination
      if (moveDirection.mag() > PVector.sub(destination, position).mag()) {
        position.set(destination);
      }
      //println("User " + userID + " - Position: (" + position.x + ", " + position.y + "), Destination: (" + destination.x + ", " + destination.y + ")");
    }
  }

  
  void drawAvatar() {
    imageMode(CENTER);
    image(avatarImage, position.x, position.y);
  }
  
  void moveTo(float x, float y) {
    destination = new PVector(width * x, height * y); // Update destination with normalized positions
  }
}

User findUserByID_party(String userID) {
  for (User user : partyUsers) {
    if (user.userID.equals(userID)) {
      return user;
    }
  }
  return null; // User not found
}

User findUserByID_networking(String userID) {
  for (User user: networkingUsers) {
    if (user.userID.equals(userID)) {
      return user;
    }
  }
  return null;
}

User findUserByID_game(String userID) {
  for (User user: gameUsers) {
    if (user.userID.equals(userID)) {
      return user;
    }
  }
  return null;
}
