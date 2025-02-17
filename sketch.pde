import java.util.Collections;
import java.util.Comparator;

/**
 * Main Processing sketch for Cloth of Gold.
 */

final int WORLD_SIZE = 100; // Increased to 100x100 grid
final int WINDOW_SIZE = 1000; // Keep window size the same
final int UPDATE_RATE = 2; // Number of frames between updates (30 ≈ 0.5 seconds)
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
final int SIMULATION_GENERATIONS = 168; // 7 days * 24 hours

void setup() {
  size(1000, 1000);
  currentWorld = new int[WORLD_SIZE][WORLD_SIZE];
  nextWorld = new int[WORLD_SIZE][WORLD_SIZE];
  placedThisTurn = new ArrayList<PVector>();
}

void draw() {
  background(220);
  displayGrid();
  
  if (isPlacementPhase) {
    // Display current player and instructions
    fill(0);
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
        fill(currentPlayer == playerA ? color(0, 0, 255, 128) : color(255, 0, 0, 128));
        rect(gridX * cellSize, gridY * cellSize, cellSize, cellSize);
      }
    }
  } else {
    // Only update if we haven't reached the generation limit
    if (generation < SIMULATION_GENERATIONS) {
      if (frameCount % UPDATE_RATE == 0) {
        updateGrid();
        generation++;
      }
      
      // Display generation counter
      fill(0);
      textSize(24);
      textAlign(LEFT);
      text("Generation: " + generation + "/" + SIMULATION_GENERATIONS, 20, WINDOW_SIZE - 20);
    } else {
      // Week is complete - return to placement phase
      fill(0);
      textSize(24);
      textAlign(CENTER);
      text("Week complete - " + playerA + "'s turn to place units", WINDOW_SIZE/2, WINDOW_SIZE - 20);
      isPlacementPhase = true;
      currentPlayer = playerA;
      generation = 0;
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
  
  // First draw the base background for all cells
  stroke(200);  // Light gray for grid lines
  for (int i = 0; i < currentWorld.length; i++) {
    for (int j = 0; j < currentWorld[i].length; j++) {
      fill(220); // Background color
      rect(i * cellSize, j * cellSize, cellSize, cellSize);
    }
  }
  
  // Calculate and draw metaball territories
  float[][] fieldA = calculateMetaballField(playerA);
  float[][] fieldB = calculateMetaballField(playerB);
  
  // Draw territories with hard boundaries
  for (int i = 0; i < WORLD_SIZE; i++) {
    for (int j = 0; j < WORLD_SIZE; j++) {
      float valueA = fieldA[i][j];
      float valueB = fieldB[i][j];
      
      if (valueA > 1.0 || valueB > 1.0) {  // Hard threshold
        if (valueA > 1.0 && valueB > 1.0) {
          fill(255, 255, 0, 64);  // Yellow with fixed alpha
        } else if (valueA > 1.0) {
          fill(0, 0, 255, 64);  // Blue with fixed alpha
        } else {
          fill(255, 0, 0, 64);  // Red with fixed alpha
        }
        noStroke();
        rect(i * cellSize, j * cellSize, cellSize, cellSize);
      }
    }
  }
  
  // Draw the actual units on top
  for (int i = 0; i < currentWorld.length; i++) {
    for (int j = 0; j < currentWorld[i].length; j++) {
      int cellValue = currentWorld[i][j];
      if (cellValue != 0) {
        color c = color(0);
        if (cellValue == playerA) c = color(0, 0, 255);
        else if (cellValue == playerB) c = color(255, 0, 0);
        else if (cellValue == neutral) c = color(255, 255, 0);
        else if (cellValue == dead) c = color(128, 0, 128);
        fill(c);
        rect(i * cellSize, j * cellSize, cellSize, cellSize);
      }
    }
  }
  
  // Calculate scores and unit counts
  int unitsA = countUnits(playerA);
  int unitsB = countUnits(playerB);
  int territoryA = countTerritory(playerA);
  int territoryB = countTerritory(playerB);
  int scoreA = unitsA - unitsB;
  int scoreB = unitsB - unitsA;
  
  // Draw semi-transparent background for text
  noStroke();
  fill(220, 220, 220, 200);
  rect(10, 10, WINDOW_SIZE - 20, 50, 5);
  
  // Display player information
  textAlign(LEFT);
  textSize(16);
  
  // Player A info (Blue)
  fill(0, 0, 255);
  text("Player A:", 20, 30);
  text("Units: " + unitsA + " | Territory: " + territoryA + " | Score: " + scoreA, 20, 50);
  
  // Player B info (Red)
  fill(255, 0, 0);
  text("Player B:", WINDOW_SIZE/2 + 20, 30);
  text("Units: " + unitsB + " | Territory: " + territoryB + " | Score: " + scoreB, WINDOW_SIZE/2 + 20, 50);
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
