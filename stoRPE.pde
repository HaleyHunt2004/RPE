import java.io.*;

// Variables for input fields
InputBox[] haveBoxes;
InputBox[] wantBoxes;
String[] haveLabels = {"Weight (kg)", "Reps", "RPE"};
String[] wantLabels = {"Target Reps", "Target RPE"};
float estimated1RM = 0, predictedWeight = 0;
boolean inputComplete = false;
Button submitButton;
Dropdown liftSelection;

// Data storage for different lifts
HashMap<String, LiftData> liftData;
String dataFile = "liftData.txt";

void setup() {
  size(500, 500);
  haveBoxes = new InputBox[3];
  wantBoxes = new InputBox[2];
  
  for (int i = 0; i < haveBoxes.length; i++) {
    haveBoxes[i] = new InputBox(50, 90 + i * 50, 150, 30, haveLabels[i]);
  }
  
  for (int i = 0; i < wantBoxes.length; i++) {
    wantBoxes[i] = new InputBox(250, 90 + i * 50, 150, 30, wantLabels[i]);
  }
  
  submitButton = new Button(50, 230, 150, 40, "Submit");
  liftSelection = new Dropdown(50, 40, 150, 30, new String[]{"Squat", "Bench", "Deadlift"});
  
  liftData = new HashMap<String, LiftData>();
  loadLiftData();
}

void draw() {
  background(255, 200, 210);
  
  // Draw selection dropdown
  liftSelection.display();
  
  // Draw section titles above input boxes
  textSize(40);
  fill(255);
  textAlign(CENTER, CENTER);
  
  // Titles for "Have" and "Want"
  text("Have", 125, 20); // Adjusted positioning
  text("Want", 320, 20); // Adjusted positioning
  
  // Draw input boxes and labels above them
  for (int i = 0; i < haveBoxes.length; i++) {
    haveBoxes[i].display();
    fill(255);
    textAlign(CENTER, CENTER);
    text(haveLabels[i], 125, 90 + i * 50 - 10); // Title above the "Have" box
  }
  
  for (int i = 0; i < wantBoxes.length; i++) {
    wantBoxes[i].display();
    fill(255);
    textAlign(CENTER, CENTER);
    text(wantLabels[i], 330, 90 + i * 50 - 10); // Title above the "Want" box
  }
  
  submitButton.display();
  
  // Draw output box for 1RM and predicted weight
  fill(255);
  rect(50, 280, 400, 50);
  fill(200, 100, 100);
  textSize(20);
  textAlign(LEFT, CENTER);
  text("E1RM: " + nf(estimated1RM, 0, 2) + "   Predicted Weight: " + nf(predictedWeight, 0, 2), 60, 310);
}

void mousePressed() {
  liftSelection.checkClick(mouseX, mouseY);
  
  for (InputBox box : haveBoxes) {
    box.checkClick(mouseX, mouseY);
  }
  
  for (InputBox box : wantBoxes) {
    box.checkClick(mouseX, mouseY);
  }
  
  if (submitButton.isClicked(mouseX, mouseY)) {
    calculateResults();
    saveLiftData();
  }
}

void keyPressed() {
  for (InputBox box : haveBoxes) {
    if (box.active) {
      box.handleInput(key);
    }
  }
  
  for (InputBox box : wantBoxes) {
    if (box.active) {
      box.handleInput(key);
    }
  }
}

class LiftData {
  float coefficient1;
  float coefficient2;
  int count;

  LiftData(float coefficient1, float coefficient2, int count) {
    this.coefficient1 = coefficient1;
    this.coefficient2 = coefficient2;
    this.count = count;
  }
}

void calculateResults() {
  float weight = haveBoxes[0].getValue();
  float reps = haveBoxes[1].getValue();
  float rpe = haveBoxes[2].getValue();
  float targetReps = wantBoxes[0].getValue();
  float targetRpe = wantBoxes[1].getValue();
  
  // Ensure all inputs are valid
  if (weight <= 0 || reps <= 0 || rpe <= 0 || targetReps <= 0 || targetRpe <= 0) {
    println("Invalid input! Please make sure all fields are filled with positive values.");
    return; // Exit the function if inputs are invalid
  }
  
  // Get dynamic coefficients for selected lift
  String selectedLift = liftSelection.getSelected();
  float formulaCoefficient1 = 0.94;
  float formulaCoefficient2 = 0.02;

  if (liftData.containsKey(selectedLift)) {
    LiftData previousData = liftData.get(selectedLift);
    formulaCoefficient1 = previousData.coefficient1;
    formulaCoefficient2 = previousData.coefficient2;
  }

  estimated1RM = weight / (formulaCoefficient1 - formulaCoefficient2 * (10 - rpe)); // Adjusted formula
  predictedWeight = estimated1RM * (formulaCoefficient1 - formulaCoefficient2 * (10 - targetRpe));

  // Store updated coefficients
  if (liftData.containsKey(selectedLift)) {
    LiftData previousData = liftData.get(selectedLift);
    formulaCoefficient1 = (formulaCoefficient1 * previousData.count + 0.94) / (previousData.count + 1); // Adjusted coefficient
    formulaCoefficient2 = (formulaCoefficient2 * previousData.count + 0.02) / (previousData.count + 1); // Adjusted coefficient
    liftData.put(selectedLift, new LiftData(formulaCoefficient1, formulaCoefficient2, previousData.count + 1));
  } else {
    liftData.put(selectedLift, new LiftData(formulaCoefficient1, formulaCoefficient2, 1)); // First time data
  }
}

void saveLiftData() {
  try {
    PrintWriter writer = new PrintWriter(new FileWriter(dataFile));
    for (String lift : liftData.keySet()) {
      LiftData data = liftData.get(lift);
      println("Saving:", lift + "," + data.coefficient1 + "," + data.coefficient2 + "," + data.count); // Debugging line
      writer.println(lift + "," + data.coefficient1 + "," + data.coefficient2 + "," + data.count);
    }
    writer.close();
  } catch (IOException e) {
    println("Error saving data: " + e.getMessage());
  }
}

void loadLiftData() {
  try {
    BufferedReader reader = new BufferedReader(new FileReader(dataFile));
    String line;
    while ((line = reader.readLine()) != null) {
      String[] parts = line.split(",");
      if (parts.length == 4) { // Adjusted for 4 parts: lift, coefficient1, coefficient2, count
        String lift = parts[0];
        float coefficient1 = Float.parseFloat(parts[1]);
        float coefficient2 = Float.parseFloat(parts[2]);
        int count = Integer.parseInt(parts[3]);
        liftData.put(lift, new LiftData(coefficient1, coefficient2, count));
        println("Loaded:", lift + " -> " + coefficient1 + "," + coefficient2 + "," + count); // Debugging line
      }
    }
    reader.close();
  } catch (IOException e) {
    println("No existing data found, starting fresh.");
  }
}

// Dropdown selection class
class Dropdown {
  float x, y, w, h;
  String[] options;
  int selectedIndex = 0;
  boolean active = false;
  
  Dropdown(float x, float y, float w, float h, String[] options) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.options = options;
  }
  
  void display() {
    fill(255);
    rect(x, y, w, h);
    fill(200, 100, 100);
    textSize(16);
    text(options[selectedIndex], x + 50, y + 15);
  }
  
  void checkClick(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
      selectedIndex = (selectedIndex + 1) % options.length;
    }
  }
  
  String getSelected() {
    return options[selectedIndex];
  }
}

// InputBox class with flashing cursor
class InputBox {
  float x, y, w, h;
  String label;
  String input = "";
  boolean active = false;
  int cursorTimer = 0;
  
  InputBox(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }
  
  void display() {
    fill(255);
    rect(x, y, w, h);
    
    if (active) {
      cursorTimer++;
      if (cursorTimer % 30 < 15) { // Flashing effect
        line(x + input.length() * 10 + 10, y + 5, x + input.length() * 10 + 10, y + h - 5); // Flashing cursor
      }
    }
    
    fill(200, 100, 100);
    textSize(16);
    textAlign(LEFT, CENTER);
    text(input, x + 10, y + h / 2);
  }
  
  void handleInput(char key) {
    if (key == BACKSPACE && input.length() > 0) {
      input = input.substring(0, input.length() - 1);
    } else if (key != CODED) {
      input += key;
    }
  }
  
  void checkClick(float mx, float my) {
    if (mx > x && mx < x + w && my > y && my < y + h) {
      active = true;
    } else {
      active = false;
    }
  }
  
  float getValue() {
    try {
      return input.isEmpty() ? 0 : Float.parseFloat(input); // Default to 0 if empty
    } catch (NumberFormatException e) {
      return 0;  // Return 0 if input is not a valid number
    }
  }
}

// Button class
class Button {
  float x, y, w, h;
  String label;
  
  Button(float x, float y, float w, float h, String label) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.label = label;
  }
  
  void display() {
    fill(250, 150, 150);
    rect(x, y, w, h);
    fill(255);
    textSize(16);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
  }
  
  boolean isClicked(float mx, float my) {
    return mx > x && mx < x + w && my > y && my < y + h;
  }
}
