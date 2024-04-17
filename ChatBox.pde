String chatText = "";
boolean isChatBoxFocused = false;


void drawChatBox() {
    if (isChatBoxFocused) {
        fill(255); // White background when focused
    } else {
        fill(200); // Lighter color when not focused
    }
    rect(50, height - 50, 400, 40, 5); // Chat input box

    fill(0); // Black text
    textFont(createFont("Arial", 16)); 
    textAlign(LEFT, CENTER);
    text(chatText, 70, height - 30); // Adjust text position slightly for better centering
  
    // Draw submit button
    fill(150); // Grey button
    rect(460, height - 50, 100, 40, 5);
    fill(0); // Black text on the button
    textAlign(CENTER, CENTER);
    text("Speak", 510, height - 30);
}


void speakText(String text) {
    if (text != null && !text.isEmpty()) {
        voice.speak(text);
    }
}
