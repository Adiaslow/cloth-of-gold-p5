import java.util.Collections;
import java.util.Comparator;
import java.util.Random;
import processing.opengl.*;

/**
 * Main Processing sketch for Cloth of Gold.
 */

final int WORLD_SIZE = 100; // Increased to 100x100 grid
final int WINDOW_SIZE = 1000; // Keep window size the same
final int UPDATE_RATE = 5; // Number of frames between updates (30 ≈ 0.5 seconds)
int[][] currentWorld; // Current state of the world
int[][] nextWorld;    // Next state of the world
char playerA = 'a';
char playerB = 'b';
char neutral = 'c';
char dead = 'd';
boolean isPlacementPhase = true;
char currentPlayer = playerA;

ArrayList<PVector> placedThisTurn;
final float PLACEMENT_RADIUS = 1;
String message = ""; // For displaying messages to players
int generation = 0;
final int SIMULATION_GENERATIONS = 288; // 24 hours in 5-minute increments

float noiseOffset;  // For noise generation
float noiseScale = 0.05;  // Controls how zoomed in/out the noise is
color[] terrainColors = {
  color(55, 130, 200),   // Water
  color(240, 220, 180),  // Sand
  color(180, 160, 130),  // Dirt
  color(120, 170, 90),   // Light grass
  color(80, 140, 70),    // Dark grass
  color(130, 130, 130)   // Stone
};

// Update color variables at the top
color playerAColor = color(255, 255, 255);  // White
color playerBColor = color(0, 0, 0);        // Black
color sharedColor = color(255, 0, 0);       // Red
color neutralColor = color(255, 140, 0);    // Orange
color deadColor = color(200, 0, 0);       // Darkred

// Update initial time (8am = 8/24 ≈ 0.333)
float initialTimeOfDay = 0.333;  // 8:00 AM

float timeOfDay = 0;  // 0 to 1 represents full day cycle
float dayLength = SIMULATION_GENERATIONS / 7.0;  // Length of one day in generations

// Add color variables for sky transitions
color skyColorDawn = color(255, 200, 150);    // Warm orange/pink
color skyColorDay = color(220);               // Light grey-blue
color skyColorDusk = color(255, 140, 100);    // Deep orange/red
color skyColorNight = color(20);              // Dark blue-black

// Replace TERRAIN_FADE_DURATION with iteration count
final int TERRAIN_FADE_ITERATIONS = 5;  // Number of iterations for fade
int[][] terrainChangeGeneration;  // Track generation number instead of frame count

// Add at the top with other global variables
int currentDay = 1;  // Track the current day
float previousTime = 0;  // Track previous time for day change detection

void setup() {
  size(1000, 1000);
  currentWorld = new int[WORLD_SIZE][WORLD_SIZE];
  nextWorld = new int[WORLD_SIZE][WORLD_SIZE];
  placedThisTurn = new ArrayList<PVector>();
  
  // Initialize noise with random offset
  noiseOffset = random(1000);
  noiseSeed(millis());
  
  // Initialize terrain change tracking with generations
  terrainChangeGeneration = new int[WORLD_SIZE][WORLD_SIZE];
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      terrainChangeGeneration[i][j] = -TERRAIN_FADE_ITERATIONS;
    }
  }
  
  timeOfDay = initialTimeOfDay;  // Set initial time to 8 AM
}

void draw() {
  // Calculate sky color based on time of day
  float adjustedTime = (timeOfDay + initialTimeOfDay) % 1.0;
  
  // Check for day change when crossing midnight
  if (previousTime > adjustedTime) {
    currentDay++;
  }
  previousTime = adjustedTime;
  
  color currentSkyColor;
  
  if (adjustedTime < 0.15) {  // Night to Dawn (3:36-7:12 AM)
    float t = map(adjustedTime, 0, 0.15, 0, 1);
    currentSkyColor = lerpColor(skyColorNight, skyColorDawn, t);
  } 
  else if (adjustedTime < 0.25) {  // Dawn to Day (7:12-9:00 AM)
    float t = map(adjustedTime, 0.15, 0.25, 0, 1);
    currentSkyColor = lerpColor(skyColorDawn, skyColorDay, t);
  } 
  else if (adjustedTime < 0.75) {  // Day (9:00 AM-6:00 PM)
    currentSkyColor = skyColorDay;
  } 
  else if (adjustedTime < 0.85) {  // Day to Dusk (6:00-8:24 PM)
    float t = map(adjustedTime, 0.75, 0.85, 0, 1);
    currentSkyColor = lerpColor(skyColorDay, skyColorDusk, t);
  } 
  else {  // Dusk to Night (8:24 PM-3:36 AM)
    float t = map(adjustedTime, 0.85, 1, 0, 1);
    currentSkyColor = lerpColor(skyColorDusk, skyColorNight, t);
  }
  
  background(currentSkyColor);
  
  // Update light level calculation in displayGrid()
  float lightLevel;
  if (adjustedTime < 0.15) {  // Night to Dawn
    lightLevel = map(adjustedTime, 0, 0.15, 0.3, 0.7);
  } 
  else if (adjustedTime < 0.25) {  // Dawn to Day
    lightLevel = map(adjustedTime, 0.15, 0.25, 0.7, 1);
  } 
  else if (adjustedTime < 0.75) {  // Day
    lightLevel = 1;
  } 
  else if (adjustedTime < 0.85) {  // Day to Dusk
    lightLevel = map(adjustedTime, 0.75, 0.85, 1, 0.7);
  } 
  else {  // Dusk to Night
    lightLevel = map(adjustedTime, 0.85, 1, 0.7, 0.3);
  }
  
  displayGrid();
  
  // Update text visibility based on sky brightness
  boolean isDark = adjustedTime < 0.15 || adjustedTime > 0.85;
  
  if (isPlacementPhase) {
    fill(isDark ? 255 : 0);  // White text at night, black during day
    textSize(24);
    textAlign(LEFT);
    String playerName = (currentPlayer == playerA) ? "Player A" : "Player B";
    int placedUnits = placedThisTurn.size();
    text(playerName + "'s turn - " + placedUnits + " units placed (max 10)", 20, WINDOW_SIZE - 40);
    text("Left click: place unit | Right click: remove unit | ENTER: end turn", 20, WINDOW_SIZE - 20);
    
    // Show error message if any
    if (!message.isEmpty()) {
      fill(255, 0, 0);
      textAlign(CENTER);
      text(message, WINDOW_SIZE/2, 70);
    }
    
    // Show placement preview
    float cellSize = WINDOW_SIZE / (float)WORLD_SIZE;
    int gridX = floor(mouseX / cellSize);
    int gridY = floor(mouseY / cellSize);
    if (gridX >= 0 && gridX < WORLD_SIZE && gridY >= 0 && gridY < WORLD_SIZE) {
      if (isValidPlacement(gridX, gridY)) {
        noStroke();
        color previewColor = (currentPlayer == playerA) ? 
          color(255, 255, 255, 128) : color(0, 0, 0, 128);
        fill(previewColor);
        ellipse(gridX * cellSize + cellSize/2, 
                gridY * cellSize + cellSize/2, 
                cellSize * 0.8, cellSize * 0.8);
      }
    }
  } else {
    if (generation < SIMULATION_GENERATIONS) {
      if (frameCount % UPDATE_RATE == 0) {
        updateGrid();
        generation++;
        // Update timeOfDay to ensure it reaches exactly 8:00 AM
        timeOfDay = (generation / (float)SIMULATION_GENERATIONS);
      }
      
    } else {
      // Week is complete - return to placement phase
      fill(isDark ? 255 : 0);
      textSize(24);
      textAlign(CENTER);
      text("Day " + currentDay + " complete - " + playerA + "'s turn to place units", WINDOW_SIZE/2, WINDOW_SIZE - 20);
      isPlacementPhase = true;
      currentPlayer = playerA;
      generation = 0;
      timeOfDay = 0;  // Reset to 0 (will be offset to 8am)
      previousTime = 0;  // Reset previousTime
      
      // Reset terrain change tracking
      for (int i = 0; i < WORLD_SIZE; i++) {
        for (int j = 0; j < WORLD_SIZE; j++) {
          terrainChangeGeneration[i][j] = -TERRAIN_FADE_ITERATIONS;
        }
      }
      
      placedThisTurn = new ArrayList<PVector>();
    }
  }
}

void keyPressed() {
  if (key == ENTER || key == RETURN) {
    if (isPlacementPhase) {
      if (placedThisTurn.size() == 0) {
        message = "You must place at least one unit!";
      } else if (placedThisTurn.size() > 10) {
        message = "You can't place more than 10 units!";
      } else {
        message = "";
        switchTurns();
      }
    }
  }
}

void mousePressed() {
  if (!isPlacementPhase) return;
  
  float cellSize = WINDOW_SIZE / (float)WORLD_SIZE;
  int gridX = floor(mouseX / cellSize);
  int gridY = floor(mouseY / cellSize);
  
  if (gridX < 0 || gridX >= WORLD_SIZE || gridY < 0 || gridY >= WORLD_SIZE) return;
  
  if (mouseButton == LEFT) {
    if (placedThisTurn.size() >= 10) {
      message = "Can't place more than 10 units!";
      return;
    }
    if (isValidPlacement(gridX, gridY)) {
      currentWorld[gridX][gridY] = currentPlayer;
      placedThisTurn.add(new PVector(gridX, gridY));
      message = "";
    }
  } else if (mouseButton == RIGHT) {
    for (int i = placedThisTurn.size() - 1; i >= 0; i--) {
      PVector pos = placedThisTurn.get(i);
      if (pos.x == gridX && pos.y == gridY) {
        currentWorld[gridX][gridY] = 0;
        placedThisTurn.remove(i);
        message = "";
        break;
      }
    }
  }
}

boolean isValidPlacement(int x, int y) {
  if (currentWorld[x][y] != 0) return false;
  if (currentWorld[x][y] == dead) return false;
  
  // Check if the placement would be in water
  float noiseVal = noise(x * noiseScale + noiseOffset, y * noiseScale + noiseOffset);
  if (noiseVal < 0.3) return false; // Can't place in water
  
  // For the very first unit of each player, ignore territory restriction
  boolean isFirstUnit = (currentPlayer == playerA && !hasPlayerPlacedFirstUnit(playerA)) ||
                       (currentPlayer == playerB && !hasPlayerPlacedFirstUnit(playerB));
  if (isFirstUnit) {
    // Only check distance from other player's units
    char otherPlayer = (currentPlayer == playerA) ? playerB : playerA;
    for (int i = max(0, x - 10); i < min(WORLD_SIZE, x + 11); i++) {
      for (int j = max(0, y - 10); j < min(WORLD_SIZE, y + 11); j++) {
        if (currentWorld[i][j] == otherPlayer) {
          float distance = dist(x, y, i, j);
          if (distance <= PLACEMENT_RADIUS) return false;
        }
      }
    }
    return true;
  }
  
  // Calculate metaball fields for both players
  float[][] currentPlayerField = calculateMetaballField(currentPlayer);
  float[][] otherPlayerField = calculateMetaballField(currentPlayer == playerA ? playerB : playerA);
  
  // Check if the placement is within exclusive territory (not in overlap)
  if (currentPlayerField[x][y] <= 1.0 || otherPlayerField[x][y] > 1.0) {
    return false; // Not in territory or in overlapping territory
  }
  
  // Check distance from other player's units
  char otherPlayer = (currentPlayer == playerA) ? playerB : playerA;
  for (int i = max(0, x - 10); i < min(WORLD_SIZE, x + 11); i++) {
    for (int j = max(0, y - 10); j < min(WORLD_SIZE, y + 11); j++) {
      if (currentWorld[i][j] == otherPlayer) {
        float distance = dist(x, y, i, j);
        if (distance <= PLACEMENT_RADIUS) return false;
      }
    }
  }
  
  return true;
}

boolean hasPlayerPlacedFirstUnit(char player) {
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      if (currentWorld[i][j] == player) {
        return true;
      }
    }
  }
  return false;
}

void switchTurns() {
  placedThisTurn.clear();
  if (currentPlayer == playerA) {
    currentPlayer = playerB;
  } else {
    currentPlayer = playerA;
    isPlacementPhase = false; // End placement phase when both players have placed their units
    startSimulation();
  }
}

void startSimulation() {
  generation = 0;
}

void displayGrid() {
  float cellSize = WINDOW_SIZE / (float)WORLD_SIZE;
  float adjustedTime = (timeOfDay + initialTimeOfDay) % 1.0;
  
  // Calculate light level (moved to draw())
  float lightLevel;
  if (adjustedTime < 0.15) {  // Night to Dawn
    lightLevel = map(adjustedTime, 0, 0.15, 0.3, 0.7);
  } 
  else if (adjustedTime < 0.25) {  // Dawn to Day
    lightLevel = map(adjustedTime, 0.15, 0.25, 0.7, 1);
  } 
  else if (adjustedTime < 0.75) {  // Day
    lightLevel = 1;
  } 
  else if (adjustedTime < 0.85) {  // Day to Dusk
    lightLevel = map(adjustedTime, 0.75, 0.85, 1, 0.7);
  } 
  else {  // Dusk to Night
    lightLevel = map(adjustedTime, 0.85, 1, 0.7, 0.3);
  }
  
  // First draw the terrain background for all cells
  noStroke();
  for (int i = 0; i < currentWorld.length; i++) {
    for (int j = 0; j < currentWorld[i].length; j++) {
      float noiseVal = noise(i * noiseScale + noiseOffset, j * noiseScale + noiseOffset);
      
      // Determine base terrain type and color
      color baseColor;
      if (noiseVal < 0.3) {
        baseColor = terrainColors[0];     // Water
        // Kill any units that touch water
        if (currentWorld[i][j] == playerA || currentWorld[i][j] == playerB || currentWorld[i][j] == neutral) {
          currentWorld[i][j] = dead;
        }
      } else if (noiseVal < 0.35) {
        baseColor = terrainColors[1];     // Sand
      } else if (noiseVal < 0.5) {
        baseColor = terrainColors[2];     // Dirt
      } else if (noiseVal < 0.7) {
        baseColor = terrainColors[3];     // Light grass
      } else if (noiseVal < 0.8) {
        baseColor = terrainColors[4];     // Dark grass
      } else {
        baseColor = terrainColors[5];     // Stone
      }
      
      // Calculate fade progress based on generations
      float fadeProgress = 1.0;
      if (currentWorld[i][j] != 0) {
        terrainChangeGeneration[i][j] = generation;
      } else {
        int generationsSinceChange = generation - terrainChangeGeneration[i][j];
        if (generationsSinceChange < TERRAIN_FADE_ITERATIONS) {
          fadeProgress = generationsSinceChange / (float)TERRAIN_FADE_ITERATIONS;
        }
      }
      
      // Get current color based on terrain type and fade
      color currentColor;
      if (noiseVal < 0.3 || noiseVal >= 0.8) {
        // Water and stone don't change
        currentColor = baseColor;
      } else {
        // Convert RGB to HSB
        colorMode(HSB, 360, 100, 100);
        float hue = hue(baseColor);
        float saturation = saturation(baseColor);
        float brightness = brightness(baseColor);
        
        // Create darker, slightly hue-shifted version
        color darkenedColor = color(
          (hue - 5) % 360,  // Shift hue towards red (negative shift)
          saturation + 10,    // Increase saturation
          brightness * 0.85   // Darken less (15% instead of 30%)
        );
        
        // Switch back to RGB for lerp
        colorMode(RGB, 255);
        currentColor = lerpColor(darkenedColor, baseColor, fadeProgress);
      }
      
      // Adjust for lighting
      currentColor = lerpColor(color(red(currentColor) * 0.3, 
                                   green(currentColor) * 0.3, 
                                   blue(currentColor) * 0.3), 
                             currentColor, 
                             lightLevel);
      
      fill(currentColor);
      rect(i * cellSize, j * cellSize, cellSize, cellSize);
    }
  }
  
  // Calculate metaball territories
  float[][] fieldA = calculateMetaballField(playerA);
  float[][] fieldB = calculateMetaballField(playerB);
  
  // Draw territory outlines with updated colors
  strokeWeight(2);
  noFill();
  
  // Draw Player A territory outline (White)
  stroke(255, 255, 255, 128);
  drawTerritoryOutline(fieldA, cellSize);
  
  // Draw Player B territory outline (Black)
  stroke(0, 0, 0, 128);
  drawTerritoryOutline(fieldB, cellSize);
  
  // Draw overlapping territory outline (Red)
  stroke(255, 0, 0, 128);
  drawOverlappingTerritoryOutline(fieldA, fieldB, cellSize);
  
  // Reset stroke settings for the rest of the drawing
  strokeWeight(1);
  
  // Draw the units with light-adjusted colors
  ellipseMode(CENTER);
  for (int i = 0; i < currentWorld.length; i++) {
    for (int j = 0; j < currentWorld[i].length; j++) {
      int cellValue = currentWorld[i][j];
      if (cellValue != 0) {
        color baseColor;
        if (cellValue == playerA) baseColor = playerAColor;
        else if (cellValue == playerB) baseColor = playerBColor;
        else if (cellValue == neutral) baseColor = neutralColor;
        else if (cellValue == dead) baseColor = deadColor;
        else continue;
        
        // Adjust color based on light level
        color adjustedColor;
        if (cellValue == playerB) {
          // For black units, brighten slightly in daylight
          adjustedColor = lerpColor(baseColor, color(50), lightLevel * 0.3);
        } else {
          // For other units, darken at night
          adjustedColor = lerpColor(color(red(baseColor) * 0.3, 
                                        green(baseColor) * 0.3, 
                                        blue(baseColor) * 0.3),
                                  baseColor, 
                                  lightLevel);
        }
        
        float centerX = i * cellSize + cellSize/2;
        float centerY = j * cellSize + cellSize/2;
        float diameter = cellSize * 0.8;
        
        noStroke();
        fill(adjustedColor);
        ellipse(centerX, centerY, diameter, diameter);
      }
    }
  }
  
  // Calculate day number (1-based)
  int currentDay = floor(timeOfDay) + 1;
  
  // Calculate scores and unit counts
  int unitsA = countUnits(playerA);
  int unitsB = countUnits(playerB);
  int territoryA = countTerritory(playerA);
  int territoryB = countTerritory(playerB);
  int scoreA = unitsA - unitsB;
  int scoreB = unitsB - unitsA;
  
  // Draw semi-transparent background for text - make it taller
  noStroke();
  fill(220, 220, 220, 200);
  rect(10, 10, WINDOW_SIZE - 20, 70, 5);  // Increased height to 70
  
  // Display time and day information
  textAlign(CENTER);
  textSize(16);
  fill(0);
  String timeString = getTimeString((timeOfDay + initialTimeOfDay) % 1.0);
  text("Day " + currentDay + " - " + timeString, WINDOW_SIZE/2, 30);
  
  // Display player information
  textAlign(LEFT);
  
  // Player A info (White)
  fill(255, 255, 255);
  text("Player A:", 20, 50);
  text("Units: " + unitsA + " | Territory: " + territoryA + " | Score: " + scoreA, 20, 70);
  
  // Player B info (Black)
  fill(0, 0, 0);
  text("Player B:", WINDOW_SIZE/2 + 20, 50);
  text("Units: " + unitsB + " | Territory: " + territoryB + " | Score: " + scoreB, WINDOW_SIZE/2 + 20, 70);
}

float[][] calculateMetaballField(char player) {
  float[][] field = new float[WORLD_SIZE][WORLD_SIZE];
  ArrayList<PVector> units = new ArrayList<PVector>();
  
  // Collect all units for this player
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      if (currentWorld[i][j] == player) {
        units.add(new PVector(i, j));
      }
    }
  }
  
  // Calculate field values
  float radius = 8.0; // Fixed radius for each ball
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      float sum = 0;
      for (PVector unit : units) {
        float dx = i - unit.x;
        float dy = j - unit.y;
        float distSquared = dx * dx + dy * dy;
        // Use inverse square for sharper boundaries
        if (distSquared < radius * radius) {
          sum += 2.0;  // Value > 1 means inside the boundary
        }
      }
      field[i][j] = sum;
    }
  }
  
  return field;
}

void updateGrid() {
  // Clear the next world array
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      nextWorld[i][j] = 0;
    }
  }
  
  // Calculate next states based on the current world
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      nextWorld[i][j] = applyRules(i, j, currentWorld);
    }
  }
  
  // Swap current and next worlds using a temporary reference
  int[][] temp = currentWorld;
  currentWorld = nextWorld;
  nextWorld = temp;
  
  // Mark terrain changes for cells that have units
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      if (currentWorld[i][j] != 0) {
        terrainChangeGeneration[i][j] = generation;
      }
    }
  }
}

int applyRules(int x, int y, int[][] currentGrid) {
  int na = countNeighbors(x, y, playerA, currentGrid);
  int nb = countNeighbors(x, y, playerB, currentGrid);
  int nc = countNeighbors(x, y, neutral, currentGrid);
  int totalNeighbors = na + nb + nc;
  int currentValue = currentGrid[x][y];
  
  // If no player units are involved in the neighborhood, use standard GoL rules
  if (na == 0 && nb == 0) {
    // Standard Game of Life rules
    if (currentValue == 0) {
      // Birth rule: exactly 3 neighbors
      return (totalNeighbors == 3) ? neutral : 0;
    } else {
      // Survival rule: 2 or 3 neighbors
      if (totalNeighbors < 2 || totalNeighbors > 3) {
        return 0; // Die from underpopulation or overpopulation
      }
      return currentValue;
    }
  }
  
  // Cloth of Gold rules when players are involved
  
  // Rule 1: Cell becomes empty (standard death)
  if ((totalNeighbors < 2 || totalNeighbors > 3) && na == nb) {
    return 0;
  }
  
  // Rule 2: Cell becomes or remains A
  if ((currentValue == 0 || currentValue == playerA || currentValue == neutral) &&
      ((currentValue != 0 && totalNeighbors >= 2 && totalNeighbors <= 3) ||
       (currentValue == 0 && totalNeighbors == 3)) &&
      na > nb) {
    return playerA;
  }
  
  // Rule 3: Cell becomes or remains B
  if ((currentValue == 0 || currentValue == playerB || currentValue == neutral) &&
      ((currentValue != 0 && totalNeighbors >= 2 && totalNeighbors <= 3) ||
       (currentValue == 0 && totalNeighbors == 3)) &&
      na < nb) {
    return playerB;
  }
  
  // Rule 4: Cell stays in current state
  if ((currentValue == 0 || currentValue == playerA || 
       currentValue == playerB || currentValue == neutral) &&
      ((currentValue != 0 && totalNeighbors >= 2 && totalNeighbors <= 3) ||
       (currentValue == 0 && totalNeighbors == 3)) &&
      na == nb) {
    return currentValue;
  }
  
  // Rule 5: Cell becomes dead (only when killed condition is met)
  if ((currentValue == playerA || currentValue == playerB) &&
      totalNeighbors >= 2 && totalNeighbors <= 3 &&
      na != nb) {
    return dead;
  }
  
  // If no other rules apply, the cell dies (becomes empty)
  return 0;
}

int countNeighbors(int x, int y, char type, int[][] currentGrid) {
  int count = 0;
  for (int i = -1; i <= 1; i++) {
    for (int j = -1; j <= 1; j++) {
      if (i == 0 && j == 0) continue;
      int nx = x + i;
      int ny = y + j;
      if (nx >= 0 && nx < currentGrid.length && 
          ny >= 0 && ny < currentGrid[0].length && 
          currentGrid[nx][ny] == type) {
        count++;
      }
    }
  }
  return count;
}

int countUnits(char player) {
  int count = 0;
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      if (currentWorld[i][j] == player) {
        count++;
      }
    }
  }
  return count;
}

int countTerritory(char player) {
  float[][] field = calculateMetaballField(player);
  int count = 0;
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      if (field[i][j] > 1.0) {
        count++;
      }
    }
  }
  return count;
}

void drawTerritoryOutline(float[][] field, float cellSize) {
  // Draw horizontal lines
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      if (field[i][j] > 1.0) {
        // Check top edge
        if (j == 0 || field[i][j-1] <= 1.0) {
          line(i * cellSize, j * cellSize, 
               (i+1) * cellSize, j * cellSize);
        }
        // Check bottom edge
        if (j == WORLD_SIZE-1 || field[i][j+1] <= 1.0) {
          line(i * cellSize, (j+1) * cellSize, 
               (i+1) * cellSize, (j+1) * cellSize);
        }
        // Check left edge
        if (i == 0 || field[i-1][j] <= 1.0) {
          line(i * cellSize, j * cellSize, 
               i * cellSize, (j+1) * cellSize);
        }
        // Check right edge
        if (i == WORLD_SIZE-1 || field[i+1][j] <= 1.0) {
          line((i+1) * cellSize, j * cellSize, 
               (i+1) * cellSize, (j+1) * cellSize);
        }
      }
    }
  }
}

void drawOverlappingTerritoryOutline(float[][] fieldA, float[][] fieldB, float cellSize) {
  // Draw horizontal lines
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      if (fieldA[i][j] > 1.0 && fieldB[i][j] > 1.0) {
        // Check top edge
        if (j == 0 || fieldA[i][j-1] <= 1.0 || fieldB[i][j-1] <= 1.0) {
          line(i * cellSize, j * cellSize, 
               (i+1) * cellSize, j * cellSize);
        }
        // Check bottom edge
        if (j == WORLD_SIZE-1 || fieldA[i][j+1] <= 1.0 || fieldB[i][j+1] <= 1.0) {
          line(i * cellSize, (j+1) * cellSize, 
               (i+1) * cellSize, (j+1) * cellSize);
        }
        // Check left edge
        if (i == 0 || fieldA[i-1][j] <= 1.0 || fieldB[i-1][j] <= 1.0) {
          line(i * cellSize, j * cellSize, 
               i * cellSize, (j+1) * cellSize);
        }
        // Check right edge
        if (i == WORLD_SIZE-1 || fieldA[i+1][j] <= 1.0 || fieldB[i+1][j] <= 1.0) {
          line((i+1) * cellSize, j * cellSize, 
               (i+1) * cellSize, (j+1) * cellSize);
        }
      }
    }
  }
}

// Update getTimeString to ensure proper time display
String getTimeString(float time) {
  int totalMinutes = floor(time * 24 * 60);  // Convert to minutes
  int hours = floor(totalMinutes / 60);
  int minutes = totalMinutes % 60;
  
  // Adjust minutes to be multiples of 5
  minutes = round(minutes / 5.0) * 5;
  
  // Handle case where rounding pushes minutes to 60
  if (minutes == 60) {
    minutes = 0;
    hours++;
  }
  
  String ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12;
  if (hours == 0) hours = 12;
  return nf(hours, 2) + ":" + nf(minutes, 2) + " " + ampm;
} 
