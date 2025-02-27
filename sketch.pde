// sketch.pde
// Main Processing sketch file for Cloth of Gold game

import java.util.Collections;
import java.util.Comparator;
import java.util.Random;
import processing.opengl.*;

/**
 * Cloth of Gold - A territory control game based on Conway's Game of Life.
 * Main sketch file that initializes and runs the game.
 */

// Game components
GameState gameState;
GridManager gridManager;
TerrainManager terrainManager;
DisplayManager displayManager;
TimeManager timeManager;
CameraManager cameraManager;
InputManager inputManager;
CoordinateTransformer transformer;

// Input tracking
boolean[] keys = new boolean[128];
boolean isDragging = false;
int lastPlacedX = -1;
int lastPlacedY = -1;
float lastMouseX, lastMouseY;

void setup() {
  fullScreen();
  surface.setTitle("Cloth of Gold");
  smooth(4);
  initializeGame();
}

void draw() {
  timeManager.update();
  inputManager.update();  // Update input manager every frame
  updateGameState();
  displayManager.draw(gameState, gridManager, timeManager);
}

void initializeGame() {
  // Initialize core components in correct order
  terrainManager = new TerrainManager();
  gameState = new GameState(terrainManager);
  timeManager = new TimeManager();
  cameraManager = new CameraManager();
  
  // Initialize dependent components
  transformer = new CoordinateTransformer(gameState, cameraManager);
  gridManager = new GridManager(gameState, terrainManager);
  displayManager = new DisplayManager(gameState, terrainManager, cameraManager);
  inputManager = new InputManager(gameState, gridManager, cameraManager, transformer);
  
  // Initialize game state
  gridManager.initialize();
  terrainManager.generateTerrain();
  timeManager.reset();
}

void updateGameState() {
  switch (gameState.getPhase()) {
    case PLACEMENT:
      gridManager.updateTerritories();
      break;
    case SIMULATION:
      if (frameCount % 2 == 0) {  // Control simulation speed
        gridManager.updateGrid();
      }
      break;
    case GAME_OVER:
      // Handle game over state
      break;
  }
}

void mousePressed() {
  inputManager.handleMousePressed();
}

void mouseReleased() {
  inputManager.handleMouseReleased();
  isDragging = false;
  lastPlacedX = -1;
  lastPlacedY = -1;
}

void mouseDragged() {
  inputManager.handleMouseDragged();
}

void mouseWheel(MouseEvent event) {
  inputManager.handleMouseWheel(event.getCount());
}

void keyPressed() {
  if (key < 128) {
    keys[key] = true;
  }
  inputManager.handleKeyPressed();
}

void keyReleased() {
  if (key < 128) {
    keys[key] = false;
  }
  inputManager.handleKeyReleased();
} 
